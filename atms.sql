/*
 Navicat Premium Data Transfer

 Source Server         : LSC
 Source Server Type    : MySQL
 Source Server Version : 100432
 Source Host           : localhost:3306
 Source Schema         : database

 Target Server Type    : MySQL
 Target Server Version : 100432
 File Encoding         : 65001

 Date: 17/11/2024 23:03:33
*/

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for atms
-- ----------------------------
DROP TABLE IF EXISTS `atms`;
CREATE TABLE `atms`  (
  `ID` int NOT NULL,
  `VirtualWorld` int NULL DEFAULT NULL,
  `Pos_X` float NULL DEFAULT NULL,
  `Pos_Y` float NULL DEFAULT NULL,
  `Pos_Z` float NULL DEFAULT NULL,
  `Rot_X` float NULL DEFAULT NULL,
  `Rot_Y` float NULL DEFAULT NULL,
  `Rot_Z` float NULL DEFAULT NULL,
  `ObjectHealth` float NULL DEFAULT NULL,
  `Money` int NOT NULL,
  `CoolDownTime` int NOT NULL,
  PRIMARY KEY (`ID`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci ROW_FORMAT = DYNAMIC;

SET FOREIGN_KEY_CHECKS = 1;
