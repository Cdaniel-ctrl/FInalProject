-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: localhost
-- Generation Time: May 10, 2025 at 07:19 AM
-- Server version: 10.4.28-MariaDB
-- PHP Version: 8.2.4

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `pharmacy_portal_db`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `AddOrUpdateUser` (IN `p_userName` VARCHAR(45), IN `p_contactInfo` VARCHAR(200), IN `p_userType` ENUM('pharmacist','patient'))   BEGIN
    DECLARE existingUserId INT;

    SELECT userId INTO existingUserId
    FROM Users
    WHERE userName = p_userName;

    IF existingUserId IS NULL THEN
        -- Insert new user
        INSERT INTO Users (userName, contactInfo, userType)
        VALUES (p_userName, p_contactInfo, p_userType);
    ELSE
        -- Update existing user's info
        UPDATE Users
        SET contactInfo = p_contactInfo,
            userType = p_userType
        WHERE userId = existingUserId;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `ProcessSale` (IN `p_prescriptionId` INT, IN `p_quantitySold` INT)   BEGIN
    -- Reduce inventory blindly (assumes prescription and inventory exist)
    UPDATE Inventory
    SET quantityAvailable = quantityAvailable - p_quantitySold,
        lastUpdated = NOW()
    WHERE medicationId = (
        SELECT medicationId
        FROM Prescriptions
        WHERE prescriptionId = p_prescriptionId
    );

    -- Record the sale
    INSERT INTO Sales (prescriptionId, saleDate, quantitySold, saleAmount)
    VALUES (p_prescriptionId, NOW(), p_quantitySold, 0.00);
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `Inventory`
--

CREATE TABLE `Inventory` (
  `inventoryId` int(11) NOT NULL,
  `medicationId` int(11) NOT NULL,
  `quantityAvailable` int(11) NOT NULL,
  `lastUpdated` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `Inventory`
--

INSERT INTO `Inventory` (`inventoryId`, `medicationId`, `quantityAvailable`, `lastUpdated`) VALUES
(1, 1, 90, '2025-05-05 14:52:26'),
(2, 2, 35, '2025-05-05 14:52:26'),
(3, 3, 68, '2025-05-05 14:52:26');

-- --------------------------------------------------------

--
-- Stand-in structure for view `medicationinventoryview`
-- (See below for the actual view)
--
CREATE TABLE `medicationinventoryview` (
`medicationName` varchar(45)
,`dosage` varchar(45)
,`manufacturer` varchar(100)
,`quantityAvailable` int(11)
);

-- --------------------------------------------------------

--
-- Table structure for table `Medications`
--

CREATE TABLE `Medications` (
  `medicationid` int(11) NOT NULL,
  `medicationName` varchar(45) NOT NULL,
  `dosage` varchar(45) NOT NULL,
  `manufacturer` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `Medications`
--

INSERT INTO `Medications` (`medicationid`, `medicationName`, `dosage`, `manufacturer`) VALUES
(1, 'Paracetamol', '500mg', 'PharmaCo'),
(2, 'Ibuprofen', '200mg', 'HealthCorp'),
(3, 'Amoxicillin', '250mg', 'MedLife'),
(4, 'Bismuth subsalicylate', '400mg', 'P&G');

-- --------------------------------------------------------

--
-- Table structure for table `Prescriptions`
--

CREATE TABLE `Prescriptions` (
  `prescriptionId` int(11) NOT NULL,
  `userId` int(11) NOT NULL,
  `medicationId` int(11) NOT NULL,
  `prescribedDate` datetime NOT NULL,
  `dosageInstructions` varchar(200) NOT NULL,
  `quantity` int(11) NOT NULL,
  `refillCount` int(11) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `Prescriptions`
--

INSERT INTO `Prescriptions` (`prescriptionId`, `userId`, `medicationId`, `prescribedDate`, `dosageInstructions`, `quantity`, `refillCount`) VALUES
(1, 1, 1, '2025-05-01 00:00:00', 'Take 1 tablet every 6 hours', 10, 2),
(2, 2, 2, '2025-05-02 00:00:00', 'Take after meals, twice a day', 15, 1),
(3, 1, 3, '2025-05-03 00:00:00', 'One capsule daily', 7, 0);

--
-- Triggers `Prescriptions`
--
DELIMITER $$
CREATE TRIGGER `AfterPrescriptionInsert` AFTER INSERT ON `Prescriptions` FOR EACH ROW BEGIN
  
    UPDATE Inventory
    SET quantityAvailable = quantityAvailable - NEW.quantity
    WHERE medicationId = NEW.medicationId;

   
    IF (SELECT quantityAvailable FROM Inventory WHERE medicationId = NEW.medicationId) < 5 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Warning: Inventory for this medication is low.';
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `Sales`
--

CREATE TABLE `Sales` (
  `saleId` int(11) NOT NULL,
  `prescriptionId` int(11) NOT NULL,
  `saleDate` datetime NOT NULL,
  `quantitySold` int(11) NOT NULL,
  `saleAmount` decimal(10,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `Sales`
--

INSERT INTO `Sales` (`saleId`, `prescriptionId`, `saleDate`, `quantitySold`, `saleAmount`) VALUES
(1, 1, '2025-05-05 15:02:44', 1, 0.00),
(2, 2, '2025-05-05 15:02:44', 2, 0.00),
(3, 3, '2025-05-05 15:02:44', 1, 0.00);

-- --------------------------------------------------------

--
-- Table structure for table `Users`
--

CREATE TABLE `Users` (
  `userId` int(11) NOT NULL,
  `userName` varchar(45) NOT NULL,
  `contactInfo` varchar(200) DEFAULT NULL,
  `userType` enum('pharmacist','patient') NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `Users`
--

INSERT INTO `Users` (`userId`, `userName`, `contactInfo`, `userType`) VALUES
(1, 'Yelena Belova', 'yelena@example.com', 'patient'),
(2, 'Bob Reynolds', 'bob@example.com', 'patient'),
(3, 'Dr. Emilia Clark', 'emilia@pharmacy.com', 'pharmacist');

-- --------------------------------------------------------

--
-- Structure for view `medicationinventoryview`
--
DROP TABLE IF EXISTS `medicationinventoryview`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `medicationinventoryview`  AS SELECT `m`.`medicationName` AS `medicationName`, `m`.`dosage` AS `dosage`, `m`.`manufacturer` AS `manufacturer`, `i`.`quantityAvailable` AS `quantityAvailable` FROM (`medications` `m` join `inventory` `i` on(`m`.`medicationid` = `i`.`medicationId`)) ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `Inventory`
--
ALTER TABLE `Inventory`
  ADD PRIMARY KEY (`inventoryId`),
  ADD UNIQUE KEY `inventoryId` (`inventoryId`),
  ADD KEY `fk_inventory_medication` (`medicationId`);

--
-- Indexes for table `Medications`
--
ALTER TABLE `Medications`
  ADD PRIMARY KEY (`medicationid`);

--
-- Indexes for table `Prescriptions`
--
ALTER TABLE `Prescriptions`
  ADD PRIMARY KEY (`prescriptionId`),
  ADD KEY `userId` (`userId`),
  ADD KEY `medicationId` (`medicationId`);

--
-- Indexes for table `Sales`
--
ALTER TABLE `Sales`
  ADD PRIMARY KEY (`saleId`),
  ADD UNIQUE KEY `saleId` (`saleId`);

--
-- Indexes for table `Users`
--
ALTER TABLE `Users`
  ADD PRIMARY KEY (`userId`),
  ADD UNIQUE KEY `userName` (`userName`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `Inventory`
--
ALTER TABLE `Inventory`
  MODIFY `inventoryId` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `Medications`
--
ALTER TABLE `Medications`
  MODIFY `medicationid` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT for table `Prescriptions`
--
ALTER TABLE `Prescriptions`
  MODIFY `prescriptionId` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `Sales`
--
ALTER TABLE `Sales`
  MODIFY `saleId` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `Users`
--
ALTER TABLE `Users`
  MODIFY `userId` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `Inventory`
--
ALTER TABLE `Inventory`
  ADD CONSTRAINT `fk_inventory_medication` FOREIGN KEY (`medicationId`) REFERENCES `Medications` (`medicationid`);

--
-- Constraints for table `Prescriptions`
--
ALTER TABLE `Prescriptions`
  ADD CONSTRAINT `fk_medication` FOREIGN KEY (`medicationId`) REFERENCES `Medications` (`medicationid`),
  ADD CONSTRAINT `fk_prescriptions_user` FOREIGN KEY (`userId`) REFERENCES `Users` (`userId`),
  ADD CONSTRAINT `fk_user` FOREIGN KEY (`userId`) REFERENCES `Users` (`userId`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
