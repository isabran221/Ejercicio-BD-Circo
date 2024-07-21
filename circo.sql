-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 21-07-2024 a las 06:18:25
-- Versión del servidor: 10.4.28-MariaDB
-- Versión de PHP: 8.2.4

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `circo`
--

DELIMITER $$
--
-- Procedimientos
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `animales_addAforoPorTipo` (`p_tipo` VARCHAR(9), `p_incaforo` SMALLINT)  COMMENT 'Hace uso del método animales_AddAforo para incrementar el aforo de las pistas donde trabajan los animales del tipo indicado' BEGIN
    -- Declaración de variables
    DECLARE V_final BOOLEAN DEFAULT FALSE;
    DECLARE V_nombrePista VARCHAR(50);
    DECLARE V_nuevoAforo SMALLINT;
    
    -- Declaración del cursor
    DECLARE C_pistas CURSOR FOR
        SELECT DISTINCT nombre_pista
        FROM ANIMALES
        WHERE tipo = p_tipo;
    
    -- Manejo del final del cursor
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET V_final = TRUE;
    
    -- Crear una tabla temporal para almacenar los resultados
    CREATE TEMPORARY TABLE T_TEMPORAL (
        nombrePista VARCHAR(50),
        nuevoAforo SMALLINT
    );
    
    -- Abrir el cursor
    OPEN C_pistas;
    
    -- Bucle para leer los datos del cursor
    read_loop: LOOP
        FETCH C_pistas INTO V_nombrePista;
        
        -- Verificar si se ha llegado al final del cursor
        IF V_final THEN
            LEAVE read_loop;
        END IF;
        
        -- Incrementar el aforo
        SET V_nuevoAforo = p_incaforo;
        CALL pistas_addAforo(V_nombrePista, V_nuevoAforo);
        
        -- Insertar el resultado en la tabla temporal
        INSERT INTO T_TEMPORAL (nombrePista, nuevoAforo) 
        VALUES (V_nombrePista, V_nuevoAforo);
    END LOOP;
    
    -- Seleccionar los resultados de la tabla temporal
    SELECT nombrePista, nuevoAforo
    FROM T_TEMPORAL
    ORDER BY nombrePista;
    
    -- Cerrar el cursor
    CLOSE C_pistas;
    
    -- Eliminar la tabla temporal
    DROP TEMPORARY TABLE T_TEMPORAL;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `artistas_addSuplementoPorCuidados` (`p_numAnimales` TINYINT)  COMMENT 'Muestra un suplemento para aquellos artistas que cuidan a más animales de lo indicado así como la suma de los complementos' BEGIN
    -- Declaración de variables
    DECLARE V_final BOOLEAN DEFAULT FALSE;
    DECLARE V_nif CHAR(9);
    DECLARE V_numAnimales TINYINT DEFAULT 0;
    DECLARE V_complementoTotal INT DEFAULT 0;
    DECLARE v_apellidos VARCHAR(100);
    DECLARE V_nombre VARCHAR(45);
    
    -- Declaración del cursor
    DECLARE C_complemento CURSOR FOR
    SELECT nif_artista, COUNT(*)
    FROM ANIMALES
    GROUP BY nif_artista
    HAVING COUNT(*) > p_numAnimales;
    
    -- Manejo del final del cursor
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET V_final = TRUE;
    
    -- Crear una tabla temporal para almacenar los resultados
    CREATE TEMPORARY TABLE T_TEMPORAL (
        nombre_completo VARCHAR(150),
        suplemento DECIMAL(6,2)
    );
    
    -- Abrir el cursor
    OPEN C_complemento;
    
    -- Bucle para leer los datos del cursor
    read_loop: LOOP
        FETCH C_complemento INTO V_nif, V_numAnimales;
        
        -- Verificar si se ha llegado al final del cursor
        IF V_final THEN
            LEAVE read_loop;
        END IF;
        
        -- Obtener apellidos y nombre del artista
        SELECT apellidos, nombre
        INTO v_apellidos, V_nombre
        FROM ARTISTAS
        WHERE nif = V_nif;
        
        -- Insertar el suplemento en la tabla temporal
        INSERT INTO T_TEMPORAL
        VALUES (CONCAT(v_apellidos, ', ', V_nombre), V_numAnimales * 100);
        
        -- Acumular el complemento total
        SET V_complementoTotal = V_complementoTotal + V_numAnimales * 100;
    END LOOP;
    
    -- Insertar el suplemento total en la tabla temporal
    INSERT INTO T_TEMPORAL
    VALUES ('Suplemento total', V_complementoTotal);
    
    -- Seleccionar los resultados de la tabla temporal
    SELECT nombre_completo, suplemento
    FROM T_TEMPORAL;
    
    -- Cerrar el cursor
    CLOSE C_complemento;
    
    -- Eliminar la tabla temporal
    DROP TEMPORARY TABLE T_TEMPORAL;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `atracciones_checkGanancias` ()  COMMENT 'Devuelve las atracciones cuya suma total de ganancias no coincide con la suma de las ganancias diarias.' BEGIN
    -- Declaración de variables
    DECLARE V_final BOOLEAN DEFAULT FALSE;
    DECLARE v_atraccion VARCHAR(50);
    DECLARE V_ganTotales INT;
    DECLARE V_ganTotalesPorDia INT;
    DECLARE V_cadenasalida VARCHAR(1000) DEFAULT '';
    
    -- Declaración del cursor
    DECLARE C_checkGanancias CURSOR FOR
    SELECT nombre, ganancias
    FROM ATRACCIONES;
    
    -- Manejo de final del cursor
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET V_final = TRUE;
    
    -- Abrir el cursor
    OPEN C_checkGanancias;
    
    -- Bucle para leer los datos del cursor
    read_loop: LOOP
        FETCH C_checkGanancias INTO v_atraccion, V_ganTotales;
        
        -- Verificar si se ha llegado al final del cursor
        IF V_final THEN
            LEAVE read_loop;
        END IF;
        
        -- Calcular las ganancias totales por día de la atracción actual
        SELECT SUM(ganancias)
        INTO V_ganTotalesPorDia
        FROM ATRACCION_DIA
        WHERE nombre_atraccion = v_atraccion;
        
        -- Comparar las ganancias y agregar a la cadena de salida si no coinciden
        IF (V_ganTotalesPorDia <> V_ganTotales) THEN
            SET V_cadenasalida = CONCAT(V_cadenasalida, IF(V_cadenasalida <> '', ', ', ''), v_atraccion, ':', V_ganTotales, ':', V_ganTotalesPorDia);
        END IF;
    END LOOP;
    
    -- Cerrar el cursor
    CLOSE C_checkGanancias;
    
    -- Seleccionar la cadena de salida con las atracciones y sus ganancias discrepantes
    SELECT V_cadenasalida AS listaatracciones;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `animales`
--

CREATE TABLE `animales` (
  `id` int(11) NOT NULL,
  `nif_artista` char(9) DEFAULT NULL,
  `tipo` varchar(50) DEFAULT NULL,
  `nombre_pista` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `artistas`
--

CREATE TABLE `artistas` (
  `nif` char(9) NOT NULL,
  `nombre` varchar(50) DEFAULT NULL,
  `apellidos` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `atracciones`
--

CREATE TABLE `atracciones` (
  `nombre` varchar(50) NOT NULL,
  `ganancias` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `atraccion_dia`
--

CREATE TABLE `atraccion_dia` (
  `id` int(11) NOT NULL,
  `nombre_atraccion` varchar(50) DEFAULT NULL,
  `ganancias` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `animales`
--
ALTER TABLE `animales`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `artistas`
--
ALTER TABLE `artistas`
  ADD PRIMARY KEY (`nif`);

--
-- Indices de la tabla `atracciones`
--
ALTER TABLE `atracciones`
  ADD PRIMARY KEY (`nombre`);

--
-- Indices de la tabla `atraccion_dia`
--
ALTER TABLE `atraccion_dia`
  ADD PRIMARY KEY (`id`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `animales`
--
ALTER TABLE `animales`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `atraccion_dia`
--
ALTER TABLE `atraccion_dia`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
