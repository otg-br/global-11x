-- phpMyAdmin SQL Dump
-- version 5.1.1deb5ubuntu1
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Tempo de geração: 07-Jul-2025 às 20:12
-- Versão do servidor: 10.6.22-MariaDB-0ubuntu0.22.04.1
-- versão do PHP: 8.1.2-1ubuntu2.21

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Banco de dados: `otg_clean`
--

-- --------------------------------------------------------

--
-- Estrutura da tabela `accounts`
--

CREATE TABLE `accounts` (
  `id` int(11) NOT NULL,
  `name` varchar(32) NOT NULL,
  `password` char(40) NOT NULL,
  `secret` char(16) DEFAULT NULL,
  `type` int(11) NOT NULL DEFAULT 1,
  `premium_ends_at` bigint(20) UNSIGNED NOT NULL DEFAULT 0,
  `coins` int(12) NOT NULL DEFAULT 0,
  `proxy_id` int(11) NOT NULL DEFAULT 0,
  `email` varchar(255) NOT NULL DEFAULT '',
  `creation` bigint(20) NOT NULL DEFAULT 0,
  `vote` int(11) NOT NULL DEFAULT 0,
  `key` varchar(20) NOT NULL DEFAULT '0',
  `email_new` varchar(255) NOT NULL DEFAULT '',
  `email_new_time` int(11) NOT NULL DEFAULT 0,
  `rlname` varchar(255) NOT NULL DEFAULT '',
  `location` varchar(255) NOT NULL DEFAULT '',
  `page_access` int(11) NOT NULL DEFAULT 0,
  `email_code` varchar(255) NOT NULL DEFAULT '',
  `next_email` int(11) NOT NULL DEFAULT 0,
  `premium_points` int(11) NOT NULL DEFAULT 0,
  `create_date` bigint(20) NOT NULL DEFAULT 0,
  `create_ip` bigint(20) NOT NULL DEFAULT 0,
  `last_post` int(11) NOT NULL DEFAULT 0,
  `flag` varchar(80) NOT NULL DEFAULT '',
  `vip_time` int(11) NOT NULL DEFAULT 0,
  `guild_points` int(11) NOT NULL DEFAULT 0,
  `guild_points_stats` int(11) NOT NULL DEFAULT 0,
  `passed` int(11) NOT NULL DEFAULT 0,
  `block` int(11) NOT NULL DEFAULT 0,
  `refresh` int(11) NOT NULL DEFAULT 0,
  `birth_date` varchar(50) NOT NULL DEFAULT '',
  `gender` varchar(20) NOT NULL DEFAULT '',
  `loyalty_points` bigint(20) NOT NULL DEFAULT 0,
  `authToken` varchar(100) NOT NULL DEFAULT '',
  `player_sell_bank` int(11) DEFAULT 0,
  `secret_status` tinyint(1) NOT NULL DEFAULT 0,
  `tournamentBalance` int(11) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Extraindo dados da tabela `accounts`
--

INSERT INTO `accounts` (`id`, `name`, `password`, `secret`, `type`, `premium_ends_at`, `coins`, `proxy_id`, `email`, `creation`, `vote`, `key`, `email_new`, `email_new_time`, `rlname`, `location`, `page_access`, `email_code`, `next_email`, `premium_points`, `create_date`, `create_ip`, `last_post`, `flag`, `vip_time`, `guild_points`, `guild_points_stats`, `passed`, `block`, `refresh`, `birth_date`, `gender`, `loyalty_points`, `authToken`, `player_sell_bank`, `secret_status`, `tournamentBalance`) VALUES
(1, '1', '21298df8a3277357ee55b01df9530b535cf08ec1', NULL, 6, 1759342628, 999249, 0, 'god@god', 0, 0, '0', '', 0, '', '', 0, '', 0, 0, 0, 0, 0, '', 1594492196, 0, 0, 0, 0, 0, '', '', 0, '', 0, 0, 0);

-- --------------------------------------------------------

--
-- Estrutura da tabela `accounts_storage`
--

CREATE TABLE `accounts_storage` (
  `account_id` int(11) NOT NULL DEFAULT 0,
  `key` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `value` int(11) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Estrutura da tabela `account_bans`
--

CREATE TABLE `account_bans` (
  `account_id` int(11) NOT NULL,
  `reason` varchar(255) NOT NULL,
  `banned_at` bigint(20) NOT NULL,
  `expires_at` bigint(20) NOT NULL,
  `banned_by` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Estrutura da tabela `account_ban_history`
--

CREATE TABLE `account_ban_history` (
  `id` int(10) UNSIGNED NOT NULL,
  `account_id` int(11) NOT NULL,
  `reason` varchar(255) NOT NULL,
  `banned_at` bigint(20) NOT NULL,
  `expired_at` bigint(20) NOT NULL,
  `banned_by` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Estrutura da tabela `account_character_sale`
--

CREATE TABLE `account_character_sale` (
  `id` int(11) NOT NULL,
  `id_account` int(11) NOT NULL,
  `id_player` int(11) NOT NULL,
  `status` tinyint(1) NOT NULL DEFAULT 0,
  `price_type` tinyint(4) NOT NULL,
  `price_coins` int(11) DEFAULT NULL,
  `price_gold` int(11) DEFAULT NULL,
  `dta_insert` datetime NOT NULL,
  `dta_valid` datetime NOT NULL,
  `dta_sale` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

-- --------------------------------------------------------

--
-- Estrutura da tabela `account_viplist`
--

CREATE TABLE `account_viplist` (
  `account_id` int(11) NOT NULL COMMENT 'id of account whose viplist entry it is',
  `player_id` int(11) NOT NULL COMMENT 'id of target player of viplist entry',
  `description` varchar(128) NOT NULL DEFAULT '',
  `icon` tinyint(2) UNSIGNED NOT NULL DEFAULT 0,
  `notify` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Estrutura da tabela `announcements`
--

CREATE TABLE `announcements` (
  `id` int(10) NOT NULL,
  `title` varchar(50) NOT NULL,
  `text` varchar(255) NOT NULL,
  `date` varchar(20) NOT NULL,
  `author` varchar(50) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Estrutura da tabela `auto_loot_list`
--

CREATE TABLE `auto_loot_list` (
  `id` int(11) NOT NULL,
  `player_id` int(11) NOT NULL,
  `item_id` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

-- --------------------------------------------------------

--
-- Estrutura da tabela `blessings_history`
--

CREATE TABLE `blessings_history` (
  `id` int(11) NOT NULL,
  `player_id` int(11) NOT NULL,
  `blessing` tinyint(4) NOT NULL,
  `loss` tinyint(1) NOT NULL,
  `timestamp` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Estrutura da tabela `boost_creature`
--

CREATE TABLE `boost_creature` (
  `category` varchar(20) NOT NULL,
  `name` varchar(100) NOT NULL,
  `exp` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `loot` int(10) UNSIGNED NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Extraindo dados da tabela `boost_creature`
--

INSERT INTO `boost_creature` (`category`, `name`, `exp`, `loot`) VALUES
('boss', 'Leviathan', 30, 36),
('normal', 'War wolf', 30, 42),
('second', 'Ancient scarab', 30, 29),
('third', 'Allukard', 30, 35);

-- --------------------------------------------------------

--
-- Estrutura da tabela `daily_reward_history`
--

CREATE TABLE `daily_reward_history` (
  `id` int(10) UNSIGNED NOT NULL,
  `streak` smallint(2) NOT NULL DEFAULT 0,
  `player_id` int(11) NOT NULL,
  `time` bigint(20) NOT NULL,
  `event` varchar(255) DEFAULT NULL,
  `instant` tinyint(3) UNSIGNED NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

-- --------------------------------------------------------

--
-- Estrutura da tabela `free_pass`
--

CREATE TABLE `free_pass` (
  `player_id` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Estrutura da tabela `global_storage`
--

CREATE TABLE `global_storage` (
  `key` varchar(32) NOT NULL,
  `value` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Extraindo dados da tabela `global_storage`
--

INSERT INTO `global_storage` (`key`, `value`) VALUES
('69799', '1594164234');

-- --------------------------------------------------------

--
-- Estrutura da tabela `guilds`
--

CREATE TABLE `guilds` (
  `id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `ownerid` int(11) NOT NULL,
  `creationdata` bigint(20) NOT NULL,
  `motd` varchar(255) NOT NULL DEFAULT '',
  `residence` int(11) NOT NULL,
  `description` text NOT NULL,
  `guild_logo` mediumblob DEFAULT NULL,
  `create_ip` bigint(20) NOT NULL DEFAULT 0,
  `balance` bigint(20) UNSIGNED NOT NULL DEFAULT 0,
  `last_execute_points` bigint(20) NOT NULL DEFAULT 0,
  `logo_gfx_name` varchar(255) NOT NULL DEFAULT '',
  `level` int(11) DEFAULT 1,
  `points` int(11) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Estrutura da tabela `guildwar_kills`
--

CREATE TABLE `guildwar_kills` (
  `id` int(11) NOT NULL,
  `killer` varchar(50) NOT NULL,
  `target` varchar(50) NOT NULL,
  `killerguild` int(11) NOT NULL DEFAULT 0,
  `targetguild` int(11) NOT NULL DEFAULT 0,
  `warid` int(11) NOT NULL DEFAULT 0,
  `time` bigint(15) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Estrutura da tabela `guild_actions_h`
--

CREATE TABLE `guild_actions_h` (
  `id` int(6) UNSIGNED NOT NULL,
  `guild_id` int(11) DEFAULT NULL,
  `player_id` int(11) NOT NULL,
  `value` int(11) NOT NULL,
  `date` bigint(20) DEFAULT NULL,
  `type` int(6) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Estrutura da tabela `guild_invites`
--

CREATE TABLE `guild_invites` (
  `player_id` int(11) NOT NULL DEFAULT 0,
  `guild_id` int(11) NOT NULL DEFAULT 0,
  `date` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Estrutura da tabela `guild_membership`
--

CREATE TABLE `guild_membership` (
  `player_id` int(11) NOT NULL,
  `guild_id` int(11) NOT NULL,
  `rank_id` int(11) NOT NULL,
  `nick` varchar(15) NOT NULL DEFAULT ''
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Estrutura da tabela `guild_ranks`
--

CREATE TABLE `guild_ranks` (
  `id` int(11) NOT NULL,
  `guild_id` int(11) NOT NULL COMMENT 'guild',
  `name` varchar(255) NOT NULL COMMENT 'rank name',
  `level` int(11) NOT NULL COMMENT 'rank level - leader, vice, member, maybe something else'
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Estrutura da tabela `guild_transfer_h`
--

CREATE TABLE `guild_transfer_h` (
  `id` int(6) UNSIGNED NOT NULL,
  `player_id` int(11) NOT NULL,
  `from_guild_id` int(6) NOT NULL,
  `to_guild_id` int(6) NOT NULL,
  `value` int(11) NOT NULL,
  `date` bigint(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Estrutura da tabela `guild_wars`
--

CREATE TABLE `guild_wars` (
  `id` int(11) NOT NULL,
  `guild1` int(11) NOT NULL DEFAULT 0,
  `guild2` int(11) NOT NULL DEFAULT 0,
  `name1` varchar(255) NOT NULL,
  `name2` varchar(255) NOT NULL,
  `status` tinyint(2) NOT NULL DEFAULT 0,
  `started` bigint(15) NOT NULL DEFAULT 0,
  `ended` bigint(15) NOT NULL DEFAULT 0,
  `frags_limit` int(10) DEFAULT 20
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Estrutura da tabela `houses`
--

CREATE TABLE `houses` (
  `id` int(11) NOT NULL,
  `owner` int(11) NOT NULL,
  `paid` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `warnings` int(11) NOT NULL DEFAULT 0,
  `name` varchar(255) NOT NULL,
  `rent` int(11) NOT NULL DEFAULT 0,
  `town_id` int(11) NOT NULL DEFAULT 0,
  `bid` int(11) NOT NULL DEFAULT 0,
  `bid_end` int(11) NOT NULL DEFAULT 0,
  `last_bid` int(11) NOT NULL DEFAULT 0,
  `highest_bidder` int(11) NOT NULL DEFAULT 0,
  `size` int(11) NOT NULL DEFAULT 0,
  `guildid` int(11) DEFAULT NULL,
  `beds` int(11) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Extraindo dados da tabela `houses`
--

INSERT INTO `houses` (`id`, `owner`, `paid`, `warnings`, `name`, `rent`, `town_id`, `bid`, `bid_end`, `last_bid`, `highest_bidder`, `size`, `guildid`, `beds`) VALUES
(1, 0, 0, 0, 'Rhyves Flats 14', 0, 2, 0, 0, 0, 0, 25, NULL, 1),
(2, 0, 0, 0, 'Rhyves Flats 15', 0, 2, 0, 0, 0, 0, 27, NULL, 1),
(3, 0, 0, 0, 'Rhyves Flats 16', 0, 2, 0, 0, 0, 0, 20, NULL, 1),
(4, 0, 0, 0, 'Baraganor Boulevard 1', 0, 3, 0, 0, 0, 0, 41, NULL, 1),
(5, 0, 0, 0, 'Saund Top 1', 0, 5, 0, 0, 0, 0, 24, NULL, 1),
(6, 0, 0, 0, 'Kazgal Close 1', 0, 3, 0, 0, 0, 0, 43, NULL, 1),
(7, 0, 0, 0, 'Tower Flat', 0, 2, 0, 0, 0, 0, 19, NULL, 1),
(8, 0, 0, 0, 'Castle Street 1', 0, 2, 0, 0, 0, 0, 40, NULL, 1),
(9, 0, 0, 0, 'Seaview 2', 0, 2, 0, 0, 0, 0, 59, NULL, 2),
(10, 0, 0, 0, 'Seaview 1', 0, 2, 0, 0, 0, 0, 40, NULL, 1),
(11, 0, 0, 0, 'Hill Hut 1', 0, 2, 0, 0, 0, 0, 35, NULL, 1),
(12, 0, 0, 0, 'Hill Hut 2', 0, 2, 0, 0, 0, 0, 35, NULL, 1),
(13, 0, 0, 0, 'Farm Lane 1', 0, 2, 0, 0, 0, 0, 31, NULL, 1),
(14, 0, 0, 0, 'Farm Lane 2', 0, 2, 0, 0, 0, 0, 54, NULL, 1),
(15, 0, 0, 0, 'Church Avenue 1', 0, 2, 0, 0, 0, 0, 29, NULL, 1),
(16, 0, 0, 0, 'Church Avenue 2', 0, 2, 0, 0, 0, 0, 29, NULL, 1),
(17, 0, 0, 0, 'Church Avenue 3', 0, 2, 0, 0, 0, 0, 49, NULL, 1),
(18, 0, 0, 0, 'Church Avenue 4', 0, 2, 0, 0, 0, 0, 36, NULL, 1),
(19, 0, 0, 0, 'Church Avenue 5', 0, 2, 0, 0, 0, 0, 28, NULL, 1),
(20, 0, 0, 0, 'Church Avenue 7', 0, 2, 0, 0, 0, 0, 32, NULL, 1),
(23, 0, 0, 0, 'City Walls 1', 0, 2, 0, 0, 0, 0, 36, NULL, 1),
(24, 0, 0, 0, 'City Walls 2', 0, 2, 0, 0, 0, 0, 36, NULL, 1),
(25, 0, 0, 0, 'City Walls 3', 0, 2, 0, 0, 0, 0, 46, NULL, 1),
(26, 0, 0, 0, 'City Walls 4', 0, 2, 0, 0, 0, 0, 46, NULL, 1),
(27, 0, 0, 0, 'Hilltop 1', 0, 2, 0, 0, 0, 0, 42, NULL, 1),
(28, 0, 0, 0, 'Hilltop 2', 0, 2, 0, 0, 0, 0, 48, NULL, 1),
(29, 0, 0, 0, 'Hilltop 3', 0, 2, 0, 0, 0, 0, 62, NULL, 1),
(30, 0, 0, 0, 'Hilltop Hall', 0, 2, 0, 0, 0, 0, 242, NULL, 2),
(31, 0, 0, 0, 'Rhyves Flats 1', 0, 2, 0, 0, 0, 0, 20, NULL, 1),
(32, 0, 0, 0, 'Rhyves Flats 2', 0, 2, 0, 0, 0, 0, 20, NULL, 1),
(33, 0, 0, 0, 'Rhyves Flats 3', 0, 2, 0, 0, 0, 0, 20, NULL, 1),
(34, 0, 0, 0, 'Rhyves Flats 4', 0, 2, 0, 0, 0, 0, 20, NULL, 1),
(35, 0, 0, 0, 'Rhyves Flats 5', 0, 2, 0, 0, 0, 0, 19, NULL, 1),
(36, 0, 0, 0, 'Rhyves Flats 6', 0, 2, 0, 0, 0, 0, 19, NULL, 1),
(37, 0, 0, 0, 'Rhyves Flats 7', 0, 2, 0, 0, 0, 0, 19, NULL, 1),
(38, 0, 0, 0, 'Rhyves Flats 8', 0, 2, 0, 0, 0, 0, 20, NULL, 1),
(39, 0, 0, 0, 'Rhyves Flats 9', 0, 2, 0, 0, 0, 0, 19, NULL, 1),
(40, 0, 0, 0, 'Rhyves Flats 10', 0, 2, 0, 0, 0, 0, 19, NULL, 1),
(41, 0, 0, 0, 'Rhyves Flats 11', 0, 2, 0, 0, 0, 0, 19, NULL, 1),
(42, 0, 0, 0, 'Rhyves Flats 13', 0, 2, 0, 0, 0, 0, 24, NULL, 1),
(43, 0, 0, 0, 'Rhyves Flats 12', 0, 2, 0, 0, 0, 0, 20, NULL, 1),
(44, 0, 0, 0, 'Baraganor Boulevard 2', 0, 3, 0, 0, 0, 0, 46, NULL, 1),
(45, 0, 0, 0, 'Baraganor Boulevard 3', 0, 3, 0, 0, 0, 0, 44, NULL, 1),
(46, 0, 0, 0, 'Baraganor Boulevard 4', 0, 3, 0, 0, 0, 0, 41, NULL, 1),
(47, 0, 0, 0, 'Baraganor Boulevard 5', 0, 3, 0, 0, 0, 0, 41, NULL, 1),
(48, 0, 0, 0, 'Baraganor Boulevard 6', 0, 3, 0, 0, 0, 0, 41, NULL, 1),
(49, 0, 0, 0, 'Baraganor Boulevard 7', 0, 3, 0, 0, 0, 0, 43, NULL, 1),
(50, 0, 0, 0, 'Baraganor Boulevard 8', 0, 3, 0, 0, 0, 0, 47, NULL, 1),
(51, 0, 0, 0, 'Kazgal Close 2', 0, 3, 0, 0, 0, 0, 42, NULL, 1),
(52, 0, 0, 0, 'Kazgal Close 3', 0, 3, 0, 0, 0, 0, 42, NULL, 1),
(53, 0, 0, 0, 'Kazgal Close 4', 0, 3, 0, 0, 0, 0, 44, NULL, 1),
(54, 0, 0, 0, 'Kazgal Close 5', 0, 3, 0, 0, 0, 0, 43, NULL, 1),
(55, 0, 0, 0, 'Kazgal Close6', 0, 3, 0, 0, 0, 0, 43, NULL, 1),
(56, 0, 0, 0, 'Kazgal Close 7', 0, 3, 0, 0, 0, 0, 43, NULL, 1),
(57, 0, 0, 0, 'Kazgal Close 8', 0, 3, 0, 0, 0, 0, 43, NULL, 1),
(58, 0, 0, 0, 'Hammersmith Hall', 0, 3, 0, 0, 0, 0, 278, NULL, 4),
(59, 0, 0, 0, 'Varnack\'s Cavern', 0, 3, 0, 0, 0, 0, 289, NULL, 4),
(60, 0, 0, 0, 'Saund Street 1', 0, 5, 0, 0, 0, 0, 20, NULL, 1),
(61, 0, 0, 0, 'Saund Street 2', 0, 5, 0, 0, 0, 0, 25, NULL, 1),
(62, 0, 0, 0, 'Saund Street 3', 0, 5, 0, 0, 0, 0, 19, NULL, 1),
(63, 0, 0, 0, 'Saund Street 4', 0, 5, 0, 0, 0, 0, 25, NULL, 1),
(64, 0, 0, 0, 'Saund Street 5', 0, 5, 0, 0, 0, 0, 19, NULL, 1),
(65, 0, 0, 0, 'Saund Top 2', 0, 5, 0, 0, 0, 0, 24, NULL, 1),
(66, 0, 0, 0, 'Saund Top 3', 0, 5, 0, 0, 0, 0, 24, NULL, 2),
(67, 0, 0, 0, 'Dock Street 1', 0, 4, 0, 0, 0, 0, 30, NULL, 1),
(68, 0, 0, 0, 'Dock Street 2', 0, 4, 0, 0, 0, 0, 35, NULL, 1),
(69, 0, 0, 0, 'Dock Street 3', 0, 4, 0, 0, 0, 0, 68, NULL, 1),
(70, 0, 0, 0, 'Nomad Hill 1', 0, 4, 0, 0, 0, 0, 27, NULL, 1),
(71, 0, 0, 0, 'Nomad Hill 2', 0, 4, 0, 0, 0, 0, 31, NULL, 1),
(72, 0, 0, 0, 'Nomad Hill 3', 0, 4, 0, 0, 0, 0, 52, NULL, 2),
(73, 0, 0, 0, 'Great Hall 1', 0, 4, 0, 0, 0, 0, 38, NULL, 1),
(74, 0, 0, 0, 'Great Hall 2', 0, 4, 0, 0, 0, 0, 43, NULL, 2),
(75, 0, 0, 0, 'Tarat Road 1', 0, 4, 0, 0, 0, 0, 36, NULL, 1),
(76, 0, 0, 0, 'Temple Terrace 1', 0, 4, 0, 0, 0, 0, 47, NULL, 1),
(77, 0, 0, 0, 'Temple Terrace 2', 0, 4, 0, 0, 0, 0, 41, NULL, 1),
(78, 0, 0, 0, 'Temple Terrace 3', 0, 4, 0, 0, 0, 0, 41, NULL, 1),
(79, 0, 0, 0, 'Tarat Road 2', 0, 4, 0, 0, 0, 0, 36, NULL, 1),
(80, 0, 0, 0, 'Tarat Road 3', 0, 4, 0, 0, 0, 0, 49, NULL, 1),
(81, 0, 0, 0, 'Tarat Road 4', 0, 4, 0, 0, 0, 0, 35, NULL, 1),
(82, 0, 0, 0, 'Tarat Road 6', 0, 4, 0, 0, 0, 0, 68, NULL, 2),
(83, 0, 0, 0, 'Tarat Road 7', 0, 4, 0, 0, 0, 0, 24, NULL, 1),
(84, 0, 0, 0, 'Tarat Road 8', 0, 4, 0, 0, 0, 0, 39, NULL, 1),
(85, 0, 0, 0, 'Tarat Road 9', 0, 4, 0, 0, 0, 0, 35, NULL, 2),
(86, 0, 0, 0, 'Smith Lane 1', 0, 4, 0, 0, 0, 0, 36, NULL, 1),
(87, 0, 0, 0, 'Smith Lane 2', 0, 4, 0, 0, 0, 0, 42, NULL, 1),
(88, 0, 0, 0, 'Smith Lane 3', 0, 4, 0, 0, 0, 0, 49, NULL, 2),
(89, 0, 0, 0, 'Smith Lane 4', 0, 4, 0, 0, 0, 0, 40, NULL, 1),
(90, 0, 0, 0, 'Smith Lane 5', 0, 4, 0, 0, 0, 0, 30, NULL, 1),
(91, 0, 0, 0, 'Smith Lane 6', 0, 4, 0, 0, 0, 0, 44, NULL, 2),
(92, 0, 0, 0, 'Smith Lane 7', 0, 4, 0, 0, 0, 0, 44, NULL, 1),
(93, 0, 0, 0, 'Smith Lane Shop', 0, 4, 0, 0, 0, 0, 52, NULL, 1),
(94, 0, 0, 0, 'Snowcapped Street 1', 0, 4, 0, 0, 0, 0, 35, NULL, 1),
(95, 0, 0, 0, 'Snowcapped Street 2', 0, 4, 0, 0, 0, 0, 30, NULL, 1),
(96, 0, 0, 0, 'Snowcapped Street 3', 0, 4, 0, 0, 0, 0, 30, NULL, 1),
(97, 0, 0, 0, 'Wall Flat 1', 0, 4, 0, 0, 0, 0, 27, NULL, 1),
(98, 0, 0, 0, 'Wall Flat 2', 0, 4, 0, 0, 0, 0, 27, NULL, 1),
(99, 0, 0, 0, 'Wall Flat 3', 0, 4, 0, 0, 0, 0, 49, NULL, 1),
(100, 0, 0, 0, 'Wall Flat 4', 0, 4, 0, 0, 0, 0, 19, NULL, 1),
(101, 0, 0, 0, 'Farm Lane 3', 0, 2, 0, 0, 0, 0, 40, NULL, 2),
(102, 0, 0, 0, 'Farm Lane 4', 0, 2, 0, 0, 0, 0, 54, NULL, 1),
(103, 0, 0, 0, 'The Square 1', 0, 2, 0, 0, 0, 0, 35, NULL, 1),
(104, 0, 0, 0, 'The Square 2 (Shop)', 0, 2, 0, 0, 0, 0, 52, NULL, 2),
(105, 0, 0, 0, 'Central Hall', 0, 2, 0, 0, 0, 0, 236, NULL, 8),
(106, 0, 0, 0, 'The Square 3', 0, 2, 0, 0, 0, 0, 29, NULL, 1),
(107, 0, 0, 0, 'The Square 4 (Shop)', 0, 2, 0, 0, 0, 0, 61, NULL, 1),
(108, 0, 0, 0, 'Church Avenue 6', 0, 2, 0, 0, 0, 0, 35, NULL, 1),
(109, 0, 0, 0, 'Castle Street 2', 0, 2, 0, 0, 0, 0, 36, NULL, 1),
(110, 0, 0, 0, 'Castle Street 3', 0, 2, 0, 0, 0, 0, 41, NULL, 1),
(111, 0, 0, 0, 'Armory Flat 1', 0, 2, 0, 0, 0, 0, 35, NULL, 2),
(112, 0, 0, 0, 'Armory Flat 2', 0, 2, 0, 0, 0, 0, 35, NULL, 1),
(194, 0, 0, 0, 'Lucky Lane 1 (Shop)', 6960, 1, 0, 0, 0, 0, 211, NULL, 4),
(208, 0, 0, 0, 'Underwood 1', 1495, 5, 0, 0, 0, 0, 41, NULL, 2),
(209, 0, 0, 0, 'Underwood 2', 1495, 5, 0, 0, 0, 0, 41, NULL, 2),
(210, 0, 0, 0, 'Underwood 5', 1370, 5, 0, 0, 0, 0, 35, NULL, 3),
(211, 0, 0, 0, 'Underwood 3', 1685, 5, 0, 0, 0, 0, 44, NULL, 3),
(212, 0, 0, 0, 'Underwood 4', 2235, 5, 0, 0, 0, 0, 56, NULL, 4),
(213, 0, 0, 0, 'Underwood 10', 585, 5, 0, 0, 0, 0, 20, NULL, 1),
(214, 0, 0, 0, 'Underwood 6', 1595, 5, 0, 0, 0, 0, 42, NULL, 3),
(215, 0, 0, 0, 'Great Willow 1a', 500, 5, 0, 0, 0, 0, 16, NULL, 1),
(216, 0, 0, 0, 'Great Willow 1b', 650, 5, 0, 0, 0, 0, 22, NULL, 1),
(217, 0, 0, 0, 'Great Willow 1c', 650, 5, 0, 0, 0, 0, 22, NULL, 1),
(218, 0, 0, 0, 'Great Willow 2d', 450, 5, 0, 0, 0, 0, 10, NULL, 1),
(219, 0, 0, 0, 'Great Willow 2c', 650, 5, 0, 0, 0, 0, 21, NULL, 1),
(220, 0, 0, 0, 'Great Willow 2b', 450, 5, 0, 0, 0, 0, 16, NULL, 1),
(221, 0, 0, 0, 'Great Willow 2a', 650, 5, 0, 0, 0, 0, 17, NULL, 1),
(222, 0, 0, 0, 'Great Willow 3d', 450, 5, 0, 0, 0, 0, 17, NULL, 1),
(223, 0, 0, 0, 'Great Willow 3c', 650, 5, 0, 0, 0, 0, 21, NULL, 1),
(224, 0, 0, 0, 'Great Willow 3b', 450, 5, 0, 0, 0, 0, 16, NULL, 1),
(225, 0, 0, 0, 'Great Willow 3a', 650, 5, 0, 0, 0, 0, 20, NULL, 1),
(226, 0, 0, 0, 'Great Willow 4b', 950, 5, 0, 0, 0, 0, 25, NULL, 2),
(227, 0, 0, 0, 'Great Willow 4c', 950, 5, 0, 0, 0, 0, 25, NULL, 2),
(228, 0, 0, 0, 'Great Willow 4d', 750, 5, 0, 0, 0, 0, 26, NULL, 1),
(229, 0, 0, 0, 'Great Willow 4a', 950, 5, 0, 0, 0, 0, 25, NULL, 2),
(230, 0, 0, 0, 'Underwood 7', 1460, 5, 0, 0, 0, 0, 39, NULL, 2),
(231, 0, 0, 0, 'Shadow Caves 3', 300, 5, 0, 0, 0, 0, 16, NULL, 1),
(232, 0, 0, 0, 'Shadow Caves 4', 300, 5, 0, 0, 0, 0, 18, NULL, 1),
(233, 0, 0, 0, 'Shadow Caves 2', 300, 5, 0, 0, 0, 0, 18, NULL, 1),
(234, 0, 0, 0, 'Shadow Caves 1', 300, 5, 0, 0, 0, 0, 16, NULL, 1),
(235, 0, 0, 0, 'Shadow Caves 17', 300, 5, 0, 0, 0, 0, 16, NULL, 1),
(236, 0, 0, 0, 'Shadow Caves 18', 300, 5, 0, 0, 0, 0, 17, NULL, 1),
(237, 0, 0, 0, 'Shadow Caves 15', 300, 5, 0, 0, 0, 0, 16, NULL, 1),
(238, 0, 0, 0, 'Shadow Caves 16', 300, 5, 0, 0, 0, 0, 17, NULL, 1),
(239, 0, 0, 0, 'Shadow Caves 13', 300, 5, 0, 0, 0, 0, 16, NULL, 1),
(240, 0, 0, 0, 'Shadow Caves 14', 300, 5, 0, 0, 0, 0, 19, NULL, 1),
(241, 0, 0, 0, 'Shadow Caves 11', 300, 5, 0, 0, 0, 0, 16, NULL, 1),
(242, 0, 0, 0, 'Shadow Caves 12', 300, 5, 0, 0, 0, 0, 18, NULL, 1),
(243, 0, 0, 0, 'Shadow Caves 27', 300, 5, 0, 0, 0, 0, 14, NULL, 1),
(244, 0, 0, 0, 'Shadow Caves 28', 300, 5, 0, 0, 0, 0, 17, NULL, 1),
(245, 0, 0, 0, 'Shadow Caves 25', 300, 5, 0, 0, 0, 0, 16, NULL, 1),
(246, 0, 0, 0, 'Shadow Caves 26', 300, 5, 0, 0, 0, 0, 17, NULL, 1),
(247, 0, 0, 0, 'Shadow Caves 23', 300, 5, 0, 0, 0, 0, 16, NULL, 1),
(248, 0, 0, 0, 'Shadow Caves 24', 300, 5, 0, 0, 0, 0, 19, NULL, 1),
(249, 0, 0, 0, 'Shadow Caves 21', 300, 5, 0, 0, 0, 0, 16, NULL, 1),
(250, 0, 0, 0, 'Shadow Caves 22', 300, 5, 0, 0, 0, 0, 17, NULL, 1),
(251, 0, 0, 0, 'Underwood 9', 585, 5, 0, 0, 0, 0, 17, NULL, 1),
(252, 0, 0, 0, 'Treetop 13', 1400, 5, 0, 0, 0, 0, 33, NULL, 2),
(254, 0, 0, 0, 'Underwood 8', 865, 5, 0, 0, 0, 0, 25, NULL, 2),
(255, 0, 0, 0, 'Mangrove 4', 950, 5, 0, 0, 0, 0, 25, NULL, 2),
(256, 0, 0, 0, 'Coastwood 10', 1630, 5, 0, 0, 0, 0, 36, NULL, 3),
(257, 0, 0, 0, 'Mangrove 1', 1750, 5, 0, 0, 0, 0, 42, NULL, 3),
(258, 0, 0, 0, 'Coastwood 1', 980, 5, 0, 0, 0, 0, 24, NULL, 2),
(259, 0, 0, 0, 'Coastwood 2', 980, 5, 0, 0, 0, 0, 24, NULL, 2),
(260, 0, 0, 0, 'Mangrove 2', 1350, 5, 0, 0, 0, 0, 33, NULL, 2),
(262, 0, 0, 0, 'Mangrove 3', 1150, 5, 0, 0, 0, 0, 29, NULL, 2),
(263, 0, 0, 0, 'Coastwood 9', 935, 5, 0, 0, 0, 0, 22, NULL, 1),
(264, 0, 0, 0, 'Coastwood 8', 1255, 5, 0, 0, 0, 0, 31, NULL, 2),
(265, 0, 0, 0, 'Coastwood 6 (Shop)', 1595, 5, 0, 0, 0, 0, 44, NULL, 1),
(266, 0, 0, 0, 'Coastwood 7', 660, 5, 0, 0, 0, 0, 19, NULL, 1),
(267, 0, 0, 0, 'Coastwood 5', 1530, 5, 0, 0, 0, 0, 35, NULL, 2),
(268, 0, 0, 0, 'Coastwood 4', 1145, 5, 0, 0, 0, 0, 30, NULL, 2),
(269, 0, 0, 0, 'Coastwood 3', 1310, 5, 0, 0, 0, 0, 34, NULL, 2),
(270, 0, 0, 0, 'Treetop 11', 900, 5, 0, 0, 0, 0, 26, NULL, 2),
(271, 0, 0, 0, 'Treetop 5 (Shop)', 1350, 5, 0, 0, 0, 0, 40, NULL, 1),
(272, 0, 0, 0, 'Treetop 7', 800, 5, 0, 0, 0, 0, 24, NULL, 1),
(273, 0, 0, 0, 'Treetop 6', 450, 5, 0, 0, 0, 0, 15, NULL, 1),
(274, 0, 0, 0, 'Treetop 8', 800, 5, 0, 0, 0, 0, 23, NULL, 1),
(275, 0, 0, 0, 'Treetop 9', 1150, 5, 0, 0, 0, 0, 30, NULL, 2),
(276, 0, 0, 0, 'Treetop 10', 1150, 5, 0, 0, 0, 0, 34, NULL, 2),
(277, 0, 0, 0, 'Treetop 4 (Shop)', 1250, 5, 0, 0, 0, 0, 40, NULL, 1),
(278, 0, 0, 0, 'Treetop 3 (Shop)', 1250, 5, 0, 0, 0, 0, 38, NULL, 1),
(279, 0, 0, 0, 'Treetop 2', 650, 5, 0, 0, 0, 0, 21, NULL, 1),
(280, 0, 0, 0, 'Treetop 1', 650, 5, 0, 0, 0, 0, 19, NULL, 1),
(281, 0, 0, 0, 'Treetop 12 (Shop)', 1350, 5, 0, 0, 0, 0, 40, NULL, 1),
(469, 0, 0, 0, 'Darashia 2, Flat 07', 1000, 10, 0, 0, 0, 0, 48, NULL, 1),
(470, 0, 0, 0, 'Darashia 2, Flat 01', 1000, 10, 0, 0, 0, 0, 48, NULL, 1),
(471, 0, 0, 0, 'Darashia 2, Flat 02', 1000, 10, 0, 0, 0, 0, 42, NULL, 1),
(472, 0, 0, 0, 'Darashia 2, Flat 06', 520, 10, 0, 0, 0, 0, 24, NULL, 1),
(473, 0, 0, 0, 'Darashia 2, Flat 05', 1260, 10, 0, 0, 0, 0, 48, NULL, 2),
(474, 0, 0, 0, 'Darashia 2, Flat 04', 520, 10, 0, 0, 0, 0, 24, NULL, 1),
(475, 0, 0, 0, 'Darashia 2, Flat 03', 1160, 10, 0, 0, 0, 0, 42, NULL, 1),
(476, 0, 0, 0, 'Darashia 2, Flat 13', 1160, 10, 0, 0, 0, 0, 42, NULL, 1),
(477, 0, 0, 0, 'Darashia 2, Flat 12', 520, 10, 0, 0, 0, 0, 24, NULL, 1),
(478, 0, 0, 0, 'Darashia 2, Flat 11', 1000, 10, 0, 0, 0, 0, 42, NULL, 1),
(479, 0, 0, 0, 'Darashia 2, Flat 14', 520, 10, 0, 0, 0, 0, 24, NULL, 1),
(480, 0, 0, 0, 'Darashia 2, Flat 15', 1260, 10, 0, 0, 0, 0, 47, NULL, 2),
(481, 0, 0, 0, 'Darashia 2, Flat 16', 680, 10, 0, 0, 0, 0, 30, NULL, 1),
(482, 0, 0, 0, 'Darashia 2, Flat 17', 1000, 10, 0, 0, 0, 0, 48, NULL, 1),
(483, 0, 0, 0, 'Darashia 2, Flat 18', 680, 10, 0, 0, 0, 0, 30, NULL, 1),
(484, 0, 0, 0, 'Darashia 1, Flat 05', 1100, 10, 0, 0, 0, 0, 48, NULL, 2),
(485, 0, 0, 0, 'Darashia 1, Flat 01', 1100, 10, 0, 0, 0, 0, 49, NULL, 2),
(486, 0, 0, 0, 'Darashia 1, Flat 04', 1000, 10, 0, 0, 0, 0, 42, NULL, 1),
(487, 0, 0, 0, 'Darashia 1, Flat 03', 2660, 10, 0, 0, 0, 0, 96, NULL, 4),
(488, 0, 0, 0, 'Darashia 1, Flat 02', 1000, 10, 0, 0, 0, 0, 41, NULL, 1),
(490, 0, 0, 0, 'Darashia 1, Flat 12', 1780, 10, 0, 0, 0, 0, 66, NULL, 2),
(491, 0, 0, 0, 'Darashia 1, Flat 11', 1100, 10, 0, 0, 0, 0, 41, NULL, 2),
(492, 0, 0, 0, 'Darashia 1, Flat 13', 1780, 10, 0, 0, 0, 0, 72, NULL, 2),
(493, 0, 0, 0, 'Darashia 1, Flat 14', 2760, 10, 0, 0, 0, 0, 108, NULL, 5),
(494, 0, 0, 0, 'Darashia 4, Flat 01', 1000, 10, 0, 0, 0, 0, 48, NULL, 1),
(495, 0, 0, 0, 'Darashia 4, Flat 05', 1100, 10, 0, 0, 0, 0, 48, NULL, 2),
(496, 0, 0, 0, 'Darashia 4, Flat 04', 1780, 10, 0, 0, 0, 0, 72, NULL, 2),
(497, 0, 0, 0, 'Darashia 4, Flat 03', 1000, 10, 0, 0, 0, 0, 42, NULL, 1),
(498, 0, 0, 0, 'Darashia 4, Flat 02', 1780, 10, 0, 0, 0, 0, 66, NULL, 2),
(499, 0, 0, 0, 'Darashia 4, Flat 13', 1780, 10, 0, 0, 0, 0, 78, NULL, 2),
(500, 0, 0, 0, 'Darashia 4, Flat 14', 1780, 10, 0, 0, 0, 0, 72, NULL, 2),
(501, 0, 0, 0, 'Darashia 4, Flat 11', 1000, 10, 0, 0, 0, 0, 41, NULL, 1),
(502, 0, 0, 0, 'Darashia 4, Flat 12', 2560, 10, 0, 0, 0, 0, 96, NULL, 3),
(503, 0, 0, 0, 'Darashia 7, Flat 05', 1225, 10, 0, 0, 0, 0, 40, NULL, 2),
(504, 0, 0, 0, 'Darashia 7, Flat 01', 1125, 10, 0, 0, 0, 0, 40, NULL, 1),
(505, 0, 0, 0, 'Darashia 7, Flat 02', 1125, 10, 0, 0, 0, 0, 41, NULL, 1),
(506, 0, 0, 0, 'Darashia 7, Flat 03', 2955, 10, 0, 0, 0, 0, 108, NULL, 4),
(507, 0, 0, 0, 'Darashia 7, Flat 04', 1125, 10, 0, 0, 0, 0, 42, NULL, 1),
(508, 0, 0, 0, 'Darashia 7, Flat 14', 2955, 10, 0, 0, 0, 0, 108, NULL, 4),
(509, 0, 0, 0, 'Darashia 7, Flat 13', 1125, 10, 0, 0, 0, 0, 42, NULL, 1),
(510, 0, 0, 0, 'Darashia 7, Flat 11', 1125, 10, 0, 0, 0, 0, 41, NULL, 1),
(511, 0, 0, 0, 'Darashia 7, Flat 12', 2955, 10, 0, 0, 0, 0, 95, NULL, 4),
(512, 0, 0, 0, 'Darashia 5, Flat 01', 1000, 10, 0, 0, 0, 0, 38, NULL, 1),
(513, 0, 0, 0, 'Darashia 5, Flat 05', 1000, 10, 0, 0, 0, 0, 48, NULL, 1),
(514, 0, 0, 0, 'Darashia 5, Flat 02', 1620, 10, 0, 0, 0, 0, 57, NULL, 2),
(515, 0, 0, 0, 'Darashia 5, Flat 03', 1000, 10, 0, 0, 0, 0, 41, NULL, 1),
(516, 0, 0, 0, 'Darashia 5, Flat 04', 1620, 10, 0, 0, 0, 0, 66, NULL, 2),
(517, 0, 0, 0, 'Darashia 5, Flat 11', 1780, 10, 0, 0, 0, 0, 66, NULL, 2),
(518, 0, 0, 0, 'Darashia 5, Flat 12', 1620, 10, 0, 0, 0, 0, 65, NULL, 2),
(519, 0, 0, 0, 'Darashia 5, Flat 13', 1780, 10, 0, 0, 0, 0, 78, NULL, 2),
(520, 0, 0, 0, 'Darashia 5, Flat 14', 1620, 10, 0, 0, 0, 0, 66, NULL, 2),
(521, 0, 0, 0, 'Darashia 6a', 3115, 10, 0, 0, 0, 0, 117, NULL, 2),
(522, 0, 0, 0, 'Darashia 6b', 3430, 10, 0, 0, 0, 0, 139, NULL, 2),
(523, 0, 0, 0, 'Darashia, Villa', 5385, 10, 0, 0, 0, 0, 233, NULL, 4),
(525, 0, 0, 0, 'Darashia, Western Guildhall', 10435, 10, 0, 0, 0, 0, 376, NULL, 14),
(526, 0, 0, 0, 'Darashia 3, Flat 01', 1100, 10, 0, 0, 0, 0, 40, NULL, 2),
(527, 0, 0, 0, 'Darashia 3, Flat 05', 1000, 10, 0, 0, 0, 0, 40, NULL, 1),
(529, 0, 0, 0, 'Darashia 3, Flat 02', 1620, 10, 0, 0, 0, 0, 65, NULL, 2),
(530, 0, 0, 0, 'Darashia 3, Flat 03', 1100, 10, 0, 0, 0, 0, 42, NULL, 2),
(531, 0, 0, 0, 'Darashia 3, Flat 04', 1620, 10, 0, 0, 0, 0, 72, NULL, 2),
(532, 0, 0, 0, 'Darashia 3, Flat 13', 1100, 10, 0, 0, 0, 0, 42, NULL, 2),
(533, 0, 0, 0, 'Darashia 3, Flat 14', 2400, 10, 0, 0, 0, 0, 102, NULL, 3),
(534, 0, 0, 0, 'Darashia 3, Flat 11', 1000, 10, 0, 0, 0, 0, 41, NULL, 1),
(535, 0, 0, 0, 'Darashia 3, Flat 12', 2600, 10, 0, 0, 0, 0, 90, NULL, 5),
(541, 0, 0, 0, 'Darashia 8, Flat 11', 1990, 10, 0, 0, 0, 0, 66, NULL, 2),
(542, 0, 0, 0, 'Darashia 8, Flat 12', 1810, 10, 0, 0, 0, 0, 65, NULL, 2),
(544, 0, 0, 0, 'Darashia 8, Flat 14', 1810, 10, 0, 0, 0, 0, 66, NULL, 2),
(545, 0, 0, 0, 'Darashia 8, Flat 13', 1990, 10, 0, 0, 0, 0, 78, NULL, 2),
(574, 0, 0, 0, 'Oskahl I j', 680, 9, 0, 0, 0, 0, 25, NULL, 1),
(575, 0, 0, 0, 'Oskahl I f', 840, 9, 0, 0, 0, 0, 34, NULL, 1),
(576, 0, 0, 0, 'Oskahl I i', 840, 9, 0, 0, 0, 0, 30, NULL, 1),
(577, 0, 0, 0, 'Oskahl I g', 1140, 9, 0, 0, 0, 0, 42, NULL, 2),
(578, 0, 0, 0, 'Oskahl I h', 1760, 9, 0, 0, 0, 0, 63, NULL, 3),
(579, 0, 0, 0, 'Oskahl I d', 1140, 9, 0, 0, 0, 0, 36, NULL, 2),
(580, 0, 0, 0, 'Oskahl I b', 840, 9, 0, 0, 0, 0, 30, NULL, 1),
(581, 0, 0, 0, 'Oskahl I c', 680, 9, 0, 0, 0, 0, 29, NULL, 1),
(582, 0, 0, 0, 'Oskahl I e', 840, 9, 0, 0, 0, 0, 33, NULL, 1),
(583, 0, 0, 0, 'Oskahl I a', 1580, 9, 0, 0, 0, 0, 52, NULL, 2),
(584, 0, 0, 0, 'Chameken I', 850, 9, 0, 0, 0, 0, 30, NULL, 1),
(585, 0, 0, 0, 'Charsirakh III', 680, 9, 0, 0, 0, 0, 30, NULL, 1),
(586, 0, 0, 0, 'Murkhol I d', 440, 9, 0, 0, 0, 0, 21, NULL, 1),
(587, 0, 0, 0, 'Murkhol I c', 440, 9, 0, 0, 0, 0, 18, NULL, 1),
(588, 0, 0, 0, 'Murkhol I b', 440, 9, 0, 0, 0, 0, 18, NULL, 1),
(589, 0, 0, 0, 'Murkhol I a', 440, 9, 0, 0, 0, 0, 20, NULL, 1),
(590, 0, 0, 0, 'Charsirakh II', 1140, 9, 0, 0, 0, 0, 39, NULL, 2),
(591, 0, 0, 0, 'Thanah II h', 1400, 9, 0, 0, 0, 0, 40, NULL, 2),
(592, 0, 0, 0, 'Thanah II g', 1650, 9, 0, 0, 0, 0, 45, NULL, 2),
(593, 0, 0, 0, 'Thanah II f', 2850, 9, 0, 0, 0, 0, 80, NULL, 3),
(594, 0, 0, 0, 'Thanah II b', 450, 9, 0, 0, 0, 0, 20, NULL, 1),
(595, 0, 0, 0, 'Thanah II c', 450, 9, 0, 0, 0, 0, 15, NULL, 1),
(596, 0, 0, 0, 'Thanah II d', 350, 9, 0, 0, 0, 0, 16, NULL, 1),
(597, 0, 0, 0, 'Thanah II e', 350, 9, 0, 0, 0, 0, 12, NULL, 1),
(599, 0, 0, 0, 'Thanah II a', 850, 9, 0, 0, 0, 0, 37, NULL, 1),
(600, 0, 0, 0, 'Thrarhor I c (Shop)', 1050, 9, 0, 0, 0, 0, 28, NULL, 1),
(601, 0, 0, 0, 'Thrarhor I d (Shop)', 1050, 9, 0, 0, 0, 0, 21, NULL, 1),
(602, 0, 0, 0, 'Thrarhor I a (Shop)', 1050, 9, 0, 0, 0, 0, 32, NULL, 1),
(603, 0, 0, 0, 'Thrarhor I b (Shop)', 1050, 9, 0, 0, 0, 0, 24, NULL, 1),
(604, 0, 0, 0, 'Thanah I c', 3250, 9, 0, 0, 0, 0, 91, NULL, 3),
(605, 0, 0, 0, 'Thanah I d', 2900, 9, 0, 0, 0, 0, 80, NULL, 4),
(606, 0, 0, 0, 'Thanah I b', 3000, 9, 0, 0, 0, 0, 84, NULL, 3),
(607, 0, 0, 0, 'Thanah I a', 850, 9, 0, 0, 0, 0, 27, NULL, 1),
(608, 0, 0, 0, 'Harrah I', 5740, 9, 0, 0, 0, 0, 190, NULL, 10),
(609, 0, 0, 0, 'Charsirakh I b', 1580, 9, 0, 0, 0, 0, 51, NULL, 2),
(610, 0, 0, 0, 'Charsirakh I a', 280, 9, 0, 0, 0, 0, 15, NULL, 1),
(611, 0, 0, 0, 'Othehothep I d', 2020, 9, 0, 0, 0, 0, 68, NULL, 4),
(612, 0, 0, 0, 'Othehothep I c', 1720, 9, 0, 0, 0, 0, 58, NULL, 3),
(613, 0, 0, 0, 'Othehothep I b', 1380, 9, 0, 0, 0, 0, 49, NULL, 2),
(614, 0, 0, 0, 'Othehothep I a', 280, 9, 0, 0, 0, 0, 14, NULL, 1),
(615, 0, 0, 0, 'Othehothep II e', 1340, 9, 0, 0, 0, 0, 44, NULL, 2),
(616, 0, 0, 0, 'Othehothep II f', 1340, 9, 0, 0, 0, 0, 44, NULL, 2),
(617, 0, 0, 0, 'Othehothep II d', 840, 9, 0, 0, 0, 0, 32, NULL, 1),
(618, 0, 0, 0, 'Othehothep II c', 840, 9, 0, 0, 0, 0, 30, NULL, 1),
(619, 0, 0, 0, 'Othehothep II b', 1920, 9, 0, 0, 0, 0, 67, NULL, 3),
(620, 0, 0, 0, 'Othehothep II a', 400, 9, 0, 0, 0, 0, 18, NULL, 1),
(621, 0, 0, 0, 'Mothrem I', 1140, 9, 0, 0, 0, 0, 38, NULL, 2),
(622, 0, 0, 0, 'Arakmehn I', 1320, 9, 0, 0, 0, 0, 41, NULL, 3),
(623, 0, 0, 0, 'Othehothep III d', 1040, 9, 0, 0, 0, 0, 36, NULL, 1),
(624, 0, 0, 0, 'Othehothep III c', 940, 9, 0, 0, 0, 0, 30, NULL, 2),
(625, 0, 0, 0, 'Othehothep III e', 840, 9, 0, 0, 0, 0, 32, NULL, 1),
(626, 0, 0, 0, 'Othehothep III f', 680, 9, 0, 0, 0, 0, 27, NULL, 1),
(627, 0, 0, 0, 'Othehothep III b', 1340, 9, 0, 0, 0, 0, 49, NULL, 2),
(628, 0, 0, 0, 'Othehothep III a', 280, 9, 0, 0, 0, 0, 14, NULL, 1),
(629, 0, 0, 0, 'Unklath I d', 1680, 9, 0, 0, 0, 0, 49, NULL, 3),
(630, 0, 0, 0, 'Unklath I e', 1580, 9, 0, 0, 0, 0, 51, NULL, 2),
(631, 0, 0, 0, 'Unklath I g', 1480, 9, 0, 0, 0, 0, 51, NULL, 1),
(632, 0, 0, 0, 'Unklath I f', 1580, 9, 0, 0, 0, 0, 51, NULL, 2),
(633, 0, 0, 0, 'Unklath I c', 1460, 9, 0, 0, 0, 0, 50, NULL, 2),
(634, 0, 0, 0, 'Unklath I b', 1460, 9, 0, 0, 0, 0, 50, NULL, 2),
(635, 0, 0, 0, 'Unklath I a', 1140, 9, 0, 0, 0, 0, 38, NULL, 2),
(636, 0, 0, 0, 'Arakmehn II', 1040, 9, 0, 0, 0, 0, 38, NULL, 1),
(637, 0, 0, 0, 'Arakmehn III', 1140, 9, 0, 0, 0, 0, 38, NULL, 2),
(638, 0, 0, 0, 'Unklath II b', 680, 9, 0, 0, 0, 0, 25, NULL, 1),
(639, 0, 0, 0, 'Unklath II c', 680, 9, 0, 0, 0, 0, 27, NULL, 1),
(640, 0, 0, 0, 'Unklath II d', 1580, 9, 0, 0, 0, 0, 52, NULL, 2),
(641, 0, 0, 0, 'Unklath II a', 1040, 9, 0, 0, 0, 0, 36, NULL, 1),
(642, 0, 0, 0, 'Arakmehn IV', 1220, 9, 0, 0, 0, 0, 41, NULL, 2),
(643, 0, 0, 0, 'Rathal I b', 680, 9, 0, 0, 0, 0, 25, NULL, 1),
(644, 0, 0, 0, 'Rathal I c', 680, 9, 0, 0, 0, 0, 27, NULL, 1),
(645, 0, 0, 0, 'Rathal I e', 780, 9, 0, 0, 0, 0, 27, NULL, 2),
(646, 0, 0, 0, 'Rathal I d', 780, 9, 0, 0, 0, 0, 27, NULL, 2),
(647, 0, 0, 0, 'Rathal I a', 1140, 9, 0, 0, 0, 0, 36, NULL, 2),
(648, 0, 0, 0, 'Rathal II b', 680, 9, 0, 0, 0, 0, 25, NULL, 1),
(649, 0, 0, 0, 'Rathal II c', 680, 9, 0, 0, 0, 0, 27, NULL, 1),
(650, 0, 0, 0, 'Rathal II d', 1460, 9, 0, 0, 0, 0, 52, NULL, 2),
(651, 0, 0, 0, 'Rathal II a', 1040, 9, 0, 0, 0, 0, 38, NULL, 1),
(653, 0, 0, 0, 'Esuph II a', 280, 9, 0, 0, 0, 0, 14, NULL, 1),
(654, 0, 0, 0, 'Uthemath II', 4460, 9, 0, 0, 0, 0, 138, NULL, 8),
(655, 0, 0, 0, 'Uthemath I e', 940, 9, 0, 0, 0, 0, 32, NULL, 2),
(656, 0, 0, 0, 'Uthemath I d', 840, 9, 0, 0, 0, 0, 30, NULL, 1),
(657, 0, 0, 0, 'Uthemath I f', 2440, 9, 0, 0, 0, 0, 86, NULL, 3),
(658, 0, 0, 0, 'Uthemath I b', 800, 9, 0, 0, 0, 0, 32, NULL, 1),
(659, 0, 0, 0, 'Uthemath I c', 900, 9, 0, 0, 0, 0, 34, NULL, 2),
(660, 0, 0, 0, 'Uthemath I a', 400, 9, 0, 0, 0, 0, 18, NULL, 1),
(661, 0, 0, 0, 'Botham I c', 1700, 9, 0, 0, 0, 0, 49, NULL, 2),
(662, 0, 0, 0, 'Botham I e', 1650, 9, 0, 0, 0, 0, 44, NULL, 2),
(663, 0, 0, 0, 'Botham I d', 3050, 9, 0, 0, 0, 0, 80, NULL, 3),
(664, 0, 0, 0, 'Botham I b', 3000, 9, 0, 0, 0, 0, 83, NULL, 3),
(666, 0, 0, 0, 'Horakhal', 9420, 9, 0, 0, 0, 0, 277, NULL, 14),
(667, 0, 0, 0, 'Esuph III b', 1340, 9, 0, 0, 0, 0, 49, NULL, 2),
(668, 0, 0, 0, 'Esuph III a', 280, 9, 0, 0, 0, 0, 14, NULL, 1),
(669, 0, 0, 0, 'Esuph IV b', 400, 9, 0, 0, 0, 0, 16, NULL, 1),
(670, 0, 0, 0, 'Esuph IV c', 400, 9, 0, 0, 0, 0, 18, NULL, 1),
(671, 0, 0, 0, 'Esuph IV d', 800, 9, 0, 0, 0, 0, 34, NULL, 1),
(672, 0, 0, 0, 'Esuph IV a', 400, 9, 0, 0, 0, 0, 16, NULL, 1),
(673, 0, 0, 0, 'Botham II e', 1650, 9, 0, 0, 0, 0, 42, NULL, 2),
(674, 0, 0, 0, 'Botham II g', 1400, 9, 0, 0, 0, 0, 38, NULL, 2),
(675, 0, 0, 0, 'Botham II f', 1650, 9, 0, 0, 0, 0, 44, NULL, 2),
(676, 0, 0, 0, 'Botham II d', 1950, 9, 0, 0, 0, 0, 49, NULL, 2),
(677, 0, 0, 0, 'Botham II c', 1250, 9, 0, 0, 0, 0, 38, NULL, 2),
(678, 0, 0, 0, 'Botham II b', 1600, 9, 0, 0, 0, 0, 47, NULL, 2),
(679, 0, 0, 0, 'Botham II a', 850, 9, 0, 0, 0, 0, 25, NULL, 1),
(680, 0, 0, 0, 'Botham III g', 1650, 9, 0, 0, 0, 0, 42, NULL, 2),
(681, 0, 0, 0, 'Botham III f', 2350, 9, 0, 0, 0, 0, 56, NULL, 3),
(682, 0, 0, 0, 'Botham III h', 3750, 9, 0, 0, 0, 0, 98, NULL, 3),
(683, 0, 0, 0, 'Botham III d', 850, 9, 0, 0, 0, 0, 27, NULL, 1),
(684, 0, 0, 0, 'Botham III e', 850, 9, 0, 0, 0, 0, 27, NULL, 1),
(685, 0, 0, 0, 'Botham III b', 950, 9, 0, 0, 0, 0, 25, NULL, 2),
(686, 0, 0, 0, 'Botham III c', 850, 9, 0, 0, 0, 0, 27, NULL, 1),
(687, 0, 0, 0, 'Botham III a', 1400, 9, 0, 0, 0, 0, 36, NULL, 2),
(688, 0, 0, 0, 'Botham IV i', 1800, 9, 0, 0, 0, 0, 51, NULL, 3),
(689, 0, 0, 0, 'Botham IV h', 1850, 9, 0, 0, 0, 0, 49, NULL, 1),
(690, 0, 0, 0, 'Botham IV f', 1700, 9, 0, 0, 0, 0, 49, NULL, 2),
(691, 0, 0, 0, 'Botham IV g', 1650, 9, 0, 0, 0, 0, 49, NULL, 2),
(692, 0, 0, 0, 'Botham IV c', 850, 9, 0, 0, 0, 0, 27, NULL, 1),
(693, 0, 0, 0, 'Botham IV e', 850, 9, 0, 0, 0, 0, 27, NULL, 1),
(694, 0, 0, 0, 'Botham IV d', 850, 9, 0, 0, 0, 0, 27, NULL, 1),
(695, 0, 0, 0, 'Botham IV b', 850, 9, 0, 0, 0, 0, 25, NULL, 1),
(696, 0, 0, 0, 'Botham IV a', 1400, 9, 0, 0, 0, 0, 36, NULL, 2),
(697, 0, 0, 0, 'Ramen Tah', 7650, 9, 0, 0, 0, 0, 184, NULL, 16),
(698, 0, 0, 0, 'Banana Bay 1', 450, 8, 0, 0, 0, 0, 25, NULL, 1),
(699, 0, 0, 0, 'Banana Bay 2', 765, 8, 0, 0, 0, 0, 36, NULL, 1),
(700, 0, 0, 0, 'Banana Bay 3', 450, 8, 0, 0, 0, 0, 25, NULL, 1),
(701, 0, 0, 0, 'Banana Bay 4', 450, 8, 0, 0, 0, 0, 25, NULL, 1),
(702, 0, 0, 0, 'Shark Manor', 8780, 8, 0, 0, 0, 0, 286, NULL, 15),
(703, 0, 0, 0, 'Coconut Quay 1', 1765, 8, 0, 0, 0, 0, 64, NULL, 2),
(704, 0, 0, 0, 'Coconut Quay 2', 1045, 8, 0, 0, 0, 0, 42, NULL, 2),
(705, 0, 0, 0, 'Coconut Quay 3', 2145, 8, 0, 0, 0, 0, 70, NULL, 4),
(706, 0, 0, 0, 'Coconut Quay 4', 2135, 8, 0, 0, 0, 0, 72, NULL, 3),
(707, 0, 0, 0, 'Crocodile Bridge 3', 1270, 8, 0, 0, 0, 0, 49, NULL, 2),
(708, 0, 0, 0, 'Crocodile Bridge 2', 865, 8, 0, 0, 0, 0, 36, NULL, 2),
(709, 0, 0, 0, 'Crocodile Bridge 1', 1045, 8, 0, 0, 0, 0, 42, NULL, 2),
(710, 0, 0, 0, 'Bamboo Garden 1', 1640, 8, 0, 0, 0, 0, 63, NULL, 3),
(711, 0, 0, 0, 'Crocodile Bridge 4', 4755, 8, 0, 0, 0, 0, 176, NULL, 4),
(712, 0, 0, 0, 'Crocodile Bridge 5', 3970, 8, 0, 0, 0, 0, 157, NULL, 2),
(713, 0, 0, 0, 'Woodway 1', 765, 8, 0, 0, 0, 0, 36, NULL, 1),
(714, 0, 0, 0, 'Woodway 2', 585, 8, 0, 0, 0, 0, 30, NULL, 1),
(715, 0, 0, 0, 'Woodway 3', 1540, 8, 0, 0, 0, 0, 65, NULL, 2),
(716, 0, 0, 0, 'Woodway 4', 405, 8, 0, 0, 0, 0, 24, NULL, 1),
(717, 0, 0, 0, 'Flamingo Flats 5', 1845, 8, 0, 0, 0, 0, 84, NULL, 1),
(718, 0, 0, 0, 'Bamboo Fortress', 21970, 8, 0, 0, 0, 0, 848, NULL, 20),
(719, 0, 0, 0, 'Bamboo Garden 3', 1540, 8, 0, 0, 0, 0, 63, NULL, 2),
(720, 0, 0, 0, 'Bamboo Garden 2', 1045, 8, 0, 0, 0, 0, 42, NULL, 2),
(721, 0, 0, 0, 'Flamingo Flats 4', 865, 8, 0, 0, 0, 0, 36, NULL, 2),
(722, 0, 0, 0, 'Flamingo Flats 2', 1045, 8, 0, 0, 0, 0, 42, NULL, 2),
(723, 0, 0, 0, 'Flamingo Flats 3', 685, 8, 0, 0, 0, 0, 30, NULL, 2),
(724, 0, 0, 0, 'Flamingo Flats 1', 685, 8, 0, 0, 0, 0, 30, NULL, 2),
(725, 0, 0, 0, 'Jungle Edge 4', 865, 8, 0, 0, 0, 0, 36, NULL, 2),
(726, 0, 0, 0, 'Jungle Edge 5', 865, 8, 0, 0, 0, 0, 36, NULL, 2),
(727, 0, 0, 0, 'Jungle Edge 6', 450, 8, 0, 0, 0, 0, 25, NULL, 1),
(728, 0, 0, 0, 'Jungle Edge 2', 3170, 8, 0, 0, 0, 0, 128, NULL, 3),
(729, 0, 0, 0, 'Jungle Edge 3', 865, 8, 0, 0, 0, 0, 36, NULL, 2),
(730, 0, 0, 0, 'Jungle Edge 1', 2495, 8, 0, 0, 0, 0, 98, NULL, 3),
(731, 0, 0, 0, 'Haggler\'s Hangout 6', 6450, 8, 0, 0, 0, 0, 208, NULL, 4),
(732, 0, 0, 0, 'Haggler\'s Hangout 5 (Shop)', 1550, 8, 0, 0, 0, 0, 56, NULL, 1),
(733, 0, 0, 0, 'Haggler\'s Hangout 4a (Shop)', 1850, 8, 0, 0, 0, 0, 56, NULL, 1),
(734, 0, 0, 0, 'Haggler\'s Hangout 4b (Shop)', 1550, 8, 0, 0, 0, 0, 56, NULL, 1),
(735, 0, 0, 0, 'Haggler\'s Hangout 3', 7550, 8, 0, 0, 0, 0, 256, NULL, 4),
(736, 0, 0, 0, 'Haggler\'s Hangout 2', 1300, 8, 0, 0, 0, 0, 49, NULL, 1),
(737, 0, 0, 0, 'Haggler\'s Hangout 1', 1400, 8, 0, 0, 0, 0, 49, NULL, 2),
(738, 0, 0, 0, 'River Homes 1', 3485, 8, 0, 0, 0, 0, 128, NULL, 3),
(739, 0, 0, 0, 'River Homes 2a', 1270, 8, 0, 0, 0, 0, 42, NULL, 2),
(740, 0, 0, 0, 'River Homes 2b', 1595, 8, 0, 0, 0, 0, 56, NULL, 3),
(741, 0, 0, 0, 'River Homes 3', 5055, 8, 0, 0, 0, 0, 176, NULL, 7),
(742, 0, 0, 0, 'The Treehouse', 24120, 8, 0, 0, 0, 0, 894, NULL, 23),
(743, 0, 0, 0, 'Corner Shop (Shop)', 2215, 12, 0, 0, 0, 0, 96, NULL, 2),
(744, 0, 0, 0, 'Tusk Flats 1', 765, 12, 0, 0, 0, 0, 40, NULL, 2),
(745, 0, 0, 0, 'Tusk Flats 2', 835, 12, 0, 0, 0, 0, 42, NULL, 2),
(746, 0, 0, 0, 'Tusk Flats 3', 660, 12, 0, 0, 0, 0, 34, NULL, 2),
(747, 0, 0, 0, 'Tusk Flats 4', 315, 12, 0, 0, 0, 0, 24, NULL, 1),
(748, 0, 0, 0, 'Tusk Flats 6', 660, 12, 0, 0, 0, 0, 35, NULL, 2),
(749, 0, 0, 0, 'Tusk Flats 5', 455, 12, 0, 0, 0, 0, 30, NULL, 1),
(750, 0, 0, 0, 'Shady Rocks 5', 2890, 12, 0, 0, 0, 0, 110, NULL, 2),
(751, 0, 0, 0, 'Shady Rocks 4 (Shop)', 2710, 12, 0, 0, 0, 0, 110, NULL, 2),
(752, 0, 0, 0, 'Shady Rocks 3', 4115, 12, 0, 0, 0, 0, 154, NULL, 3),
(753, 0, 0, 0, 'Shady Rocks 2', 2010, 12, 0, 0, 0, 0, 77, NULL, 4),
(754, 0, 0, 0, 'Shady Rocks 1', 3630, 12, 0, 0, 0, 0, 132, NULL, 4),
(755, 0, 0, 0, 'Crystal Glance', 19625, 12, 0, 0, 0, 0, 569, NULL, 24),
(756, 0, 0, 0, 'Arena Walk 3', 3550, 12, 0, 0, 0, 0, 126, NULL, 3),
(757, 0, 0, 0, 'Arena Walk 2', 1400, 12, 0, 0, 0, 0, 54, NULL, 2),
(758, 0, 0, 0, 'Arena Walk 1', 3250, 12, 0, 0, 0, 0, 128, NULL, 3),
(759, 0, 0, 0, 'Bears Paw 2', 2305, 12, 0, 0, 0, 0, 100, NULL, 2),
(760, 0, 0, 0, 'Bears Paw 1', 1810, 12, 0, 0, 0, 0, 72, NULL, 2),
(761, 0, 0, 0, 'Spirit Homes 5', 1450, 12, 0, 0, 0, 0, 56, NULL, 2),
(762, 0, 0, 0, 'Glacier Side 3', 1950, 12, 0, 0, 0, 0, 75, NULL, 2),
(763, 0, 0, 0, 'Glacier Side 2', 4750, 12, 0, 0, 0, 0, 154, NULL, 3),
(764, 0, 0, 0, 'Glacier Side 1', 1600, 12, 0, 0, 0, 0, 65, NULL, 2),
(765, 0, 0, 0, 'Spirit Homes 1', 1700, 12, 0, 0, 0, 0, 56, NULL, 2),
(766, 0, 0, 0, 'Spirit Homes 2', 1900, 12, 0, 0, 0, 0, 72, NULL, 2),
(767, 0, 0, 0, 'Spirit Homes 3', 4250, 12, 0, 0, 0, 0, 128, NULL, 3),
(768, 0, 0, 0, 'Spirit Homes 4', 1100, 12, 0, 0, 0, 0, 49, NULL, 1),
(770, 0, 0, 0, 'Glacier Side 4', 2050, 12, 0, 0, 0, 0, 75, NULL, 1),
(771, 0, 0, 0, 'Shelf Site', 4800, 12, 0, 0, 0, 0, 160, NULL, 3),
(772, 0, 0, 0, 'Raven Corner 1', 855, 12, 0, 0, 0, 0, 45, NULL, 1),
(773, 0, 0, 0, 'Raven Corner 2', 1685, 12, 0, 0, 0, 0, 60, NULL, 3),
(774, 0, 0, 0, 'Raven Corner 3', 855, 12, 0, 0, 0, 0, 45, NULL, 1),
(775, 0, 0, 0, 'Bears Paw 3', 2090, 12, 0, 0, 0, 0, 82, NULL, 3),
(776, 0, 0, 0, 'Bears Paw 4', 5205, 12, 0, 0, 0, 0, 189, NULL, 4),
(778, 0, 0, 0, 'Bears Paw 5', 2045, 12, 0, 0, 0, 0, 81, NULL, 3),
(779, 0, 0, 0, 'Trout Plaza 5 (Shop)', 3880, 12, 0, 0, 0, 0, 144, NULL, 2),
(780, 0, 0, 0, 'Pilchard Bin 1', 685, 12, 0, 0, 0, 0, 30, NULL, 2),
(781, 0, 0, 0, 'Pilchard Bin 2', 685, 12, 0, 0, 0, 0, 24, NULL, 2),
(782, 0, 0, 0, 'Pilchard Bin 3', 585, 12, 0, 0, 0, 0, 24, NULL, 1),
(783, 0, 0, 0, 'Pilchard Bin 4', 585, 12, 0, 0, 0, 0, 24, NULL, 1),
(784, 0, 0, 0, 'Pilchard Bin 5', 685, 12, 0, 0, 0, 0, 24, NULL, 2),
(785, 0, 0, 0, 'Pilchard Bin 10', 450, 12, 0, 0, 0, 0, 20, NULL, 1),
(786, 0, 0, 0, 'Pilchard Bin 9', 450, 12, 0, 0, 0, 0, 20, NULL, 1),
(787, 0, 0, 0, 'Pilchard Bin 8', 450, 12, 0, 0, 0, 0, 20, NULL, 2),
(789, 0, 0, 0, 'Pilchard Bin 7', 450, 12, 0, 0, 0, 0, 20, NULL, 1),
(790, 0, 0, 0, 'Pilchard Bin 6', 450, 12, 0, 0, 0, 0, 25, NULL, 1),
(791, 0, 0, 0, 'Trout Plaza 1', 2395, 12, 0, 0, 0, 0, 112, NULL, 2),
(792, 0, 0, 0, 'Trout Plaza 2', 1540, 12, 0, 0, 0, 0, 64, NULL, 2),
(793, 0, 0, 0, 'Trout Plaza 3', 900, 12, 0, 0, 0, 0, 36, NULL, 1),
(794, 0, 0, 0, 'Trout Plaza 4', 900, 12, 0, 0, 0, 0, 45, NULL, 1),
(795, 0, 0, 0, 'Skiffs End 1', 1540, 12, 0, 0, 0, 0, 70, NULL, 2),
(796, 0, 0, 0, 'Skiffs End 2', 910, 12, 0, 0, 0, 0, 42, NULL, 2),
(797, 0, 0, 0, 'Furrier Quarter 3', 1010, 12, 0, 0, 0, 0, 54, NULL, 2),
(798, 0, 0, 0, 'Mammoth Belly', 22810, 12, 0, 0, 0, 0, 634, NULL, 30),
(799, 0, 0, 0, 'Furrier Quarter 2', 1045, 12, 0, 0, 0, 0, 56, NULL, 2),
(800, 0, 0, 0, 'Furrier Quarter 1', 1635, 12, 0, 0, 0, 0, 84, NULL, 3),
(801, 0, 0, 0, 'Fimbul Shelf 3', 1255, 12, 0, 0, 0, 0, 66, NULL, 2),
(802, 0, 0, 0, 'Fimbul Shelf 4', 1045, 12, 0, 0, 0, 0, 56, NULL, 2),
(803, 0, 0, 0, 'Fimbul Shelf 2', 1045, 12, 0, 0, 0, 0, 56, NULL, 2),
(804, 0, 0, 0, 'Fimbul Shelf 1', 975, 12, 0, 0, 0, 0, 48, NULL, 2),
(805, 0, 0, 0, 'Frost Manor', 26370, 12, 0, 0, 0, 0, 806, NULL, 24),
(831, 0, 0, 0, 'Marble Guildhall', 16810, 3, 0, 0, 0, 0, 530, NULL, 17),
(832, 0, 0, 0, 'Iron Guildhall', 15560, 3, 0, 0, 0, 0, 464, NULL, 17),
(833, 0, 0, 0, 'The Market 1 (Shop)', 650, 3, 0, 0, 0, 0, 25, NULL, 1),
(834, 0, 0, 0, 'The Market 3 (Shop)', 1450, 3, 0, 0, 0, 0, 40, NULL, 1),
(835, 0, 0, 0, 'The Market 2 (Shop)', 1100, 3, 0, 0, 0, 0, 40, NULL, 1),
(836, 0, 0, 0, 'The Market 4 (Shop)', 1800, 3, 0, 0, 0, 0, 48, NULL, 1),
(837, 0, 0, 0, 'Granite Guildhall', 17845, 3, 0, 0, 0, 0, 530, NULL, 17),
(838, 0, 0, 0, 'Upper Barracks 1', 210, 3, 0, 0, 0, 0, 14, NULL, 1),
(850, 0, 0, 0, 'Upper Barracks 13', 580, 3, 0, 0, 0, 0, 24, NULL, 2),
(851, 0, 0, 0, 'Nobility Quarter 4', 765, 3, 0, 0, 0, 0, 25, NULL, 1),
(852, 0, 0, 0, 'Nobility Quarter 5', 765, 3, 0, 0, 0, 0, 25, NULL, 1),
(853, 0, 0, 0, 'Nobility Quarter 7', 765, 3, 0, 0, 0, 0, 25, NULL, 1),
(854, 0, 0, 0, 'Nobility Quarter 6', 765, 3, 0, 0, 0, 0, 26, NULL, 1),
(855, 0, 0, 0, 'Nobility Quarter 8', 765, 3, 0, 0, 0, 0, 26, NULL, 1),
(856, 0, 0, 0, 'Nobility Quarter 9', 765, 3, 0, 0, 0, 0, 26, NULL, 1),
(857, 0, 0, 0, 'Nobility Quarter 2', 1865, 3, 0, 0, 0, 0, 50, NULL, 3),
(858, 0, 0, 0, 'Nobility Quarter 3', 1865, 3, 0, 0, 0, 0, 50, NULL, 3),
(859, 0, 0, 0, 'Nobility Quarter 1', 1865, 3, 0, 0, 0, 0, 50, NULL, 3),
(863, 0, 0, 0, 'The Farms 6, Fishing Hut', 1255, 3, 0, 0, 0, 0, 32, NULL, 2),
(864, 0, 0, 0, 'The Farms 5', 1530, 3, 0, 0, 0, 0, 36, NULL, 2),
(866, 0, 0, 0, 'The Farms 3', 1530, 3, 0, 0, 0, 0, 36, NULL, 2),
(867, 0, 0, 0, 'The Farms 2', 1530, 3, 0, 0, 0, 0, 36, NULL, 2),
(868, 0, 0, 0, 'The Farms 1', 2510, 3, 0, 0, 0, 0, 60, NULL, 3),
(886, 0, 0, 0, 'Outlaw Castle', 8000, 3, 0, 0, 0, 0, 307, NULL, 9),
(889, 0, 0, 0, 'Tunnel Gardens 3', 2000, 3, 0, 0, 0, 0, 43, NULL, 3),
(890, 0, 0, 0, 'Tunnel Gardens 4', 2000, 3, 0, 0, 0, 0, 42, NULL, 3),
(892, 0, 0, 0, 'Tunnel Gardens 5', 1360, 3, 0, 0, 0, 0, 35, NULL, 2),
(893, 0, 0, 0, 'Tunnel Gardens 6', 1360, 3, 0, 0, 0, 0, 38, NULL, 2),
(894, 0, 0, 0, 'Tunnel Gardens 8', 1360, 3, 0, 0, 0, 0, 35, NULL, 2),
(895, 0, 0, 0, 'Tunnel Gardens 7', 1360, 3, 0, 0, 0, 0, 35, NULL, 2),
(900, 0, 0, 0, 'Wolftower', 21550, 3, 0, 0, 0, 0, 638, NULL, 23),
(901, 0, 0, 0, 'Paupers Palace, Flat 11', 315, 1, 0, 0, 0, 0, 12, NULL, 1),
(905, 0, 0, 0, 'Botham I a', 950, 9, 0, 0, 0, 0, 36, NULL, 1),
(906, 0, 0, 0, 'Esuph I', 680, 9, 0, 0, 0, 0, 39, NULL, 1),
(907, 0, 0, 0, 'Esuph II b', 1380, 9, 0, 0, 0, 0, 51, NULL, 2),
(1883, 0, 0, 0, 'Aureate Court 1', 5240, 13, 0, 0, 0, 0, 276, NULL, 3),
(1884, 0, 0, 0, 'Aureate Court 2', 4860, 13, 0, 0, 0, 0, 201, NULL, 2),
(1885, 0, 0, 0, 'Aureate Court 3', 4300, 13, 0, 0, 0, 0, 228, NULL, 2),
(1886, 0, 0, 0, 'Aureate Court 4', 3980, 13, 0, 0, 0, 0, 210, NULL, 4),
(1887, 0, 0, 0, 'Fortune Wing 1', 10180, 13, 0, 0, 0, 0, 422, NULL, 4),
(1888, 0, 0, 0, 'Fortune Wing 2', 5580, 13, 0, 0, 0, 0, 260, NULL, 2),
(1889, 0, 0, 0, 'Fortune Wing 3', 5740, 13, 0, 0, 0, 0, 258, NULL, 2),
(1890, 0, 0, 0, 'Fortune Wing 4', 5740, 13, 0, 0, 0, 0, 306, NULL, 4),
(1891, 0, 0, 0, 'Luminous Arc 1', 6460, 13, 0, 0, 0, 0, 344, NULL, 2),
(1892, 0, 0, 0, 'Luminous Arc 2', 6460, 13, 0, 0, 0, 0, 301, NULL, 4),
(1893, 0, 0, 0, 'Luminous Arc 3', 5400, 13, 0, 0, 0, 0, 249, NULL, 3),
(1894, 0, 0, 0, 'Luminous Arc 4', 8000, 13, 0, 0, 0, 0, 343, NULL, 5),
(1895, 0, 0, 0, 'Radiant Plaza 1', 5620, 13, 0, 0, 0, 0, 276, NULL, 4),
(1896, 0, 0, 0, 'Radiant Plaza 2', 3820, 13, 0, 0, 0, 0, 179, NULL, 2),
(1897, 0, 0, 0, 'Radiant Plaza 3', 4900, 13, 0, 0, 0, 0, 257, NULL, 2),
(1898, 0, 0, 0, 'Radiant Plaza 4', 7460, 13, 0, 0, 0, 0, 367, NULL, 3),
(1899, 0, 0, 0, 'Sun Palace', 23120, 13, 0, 0, 0, 0, 976, NULL, 27),
(1900, 0, 0, 0, 'Halls of Serenity', 23360, 13, 0, 0, 0, 0, 1093, NULL, 33),
(1901, 0, 0, 0, 'Cascade Towers', 19500, 13, 0, 0, 0, 0, 811, NULL, 33),
(1902, 0, 0, 0, 'Sorcerer\'s Avenue 5', 2695, 2, 0, 0, 0, 0, 96, NULL, 1),
(1903, 0, 0, 0, 'Sorcerer\'s Avenue 1a', 1255, 2, 0, 0, 0, 0, 42, NULL, 2),
(1904, 0, 0, 0, 'Sorcerer\'s Avenue 1b', 1035, 2, 0, 0, 0, 0, 36, NULL, 2),
(1905, 0, 0, 0, 'Sorcerer\'s Avenue 1c', 1255, 2, 0, 0, 0, 0, 36, NULL, 2),
(1906, 0, 0, 0, 'Beach Home Apartments, Flat 06', 1145, 2, 0, 0, 0, 0, 40, NULL, 2),
(1907, 0, 0, 0, 'Beach Home Apartments, Flat 01', 715, 2, 0, 0, 0, 0, 30, NULL, 1),
(1908, 0, 0, 0, 'Beach Home Apartments, Flat 02', 715, 2, 0, 0, 0, 0, 25, NULL, 1),
(1909, 0, 0, 0, 'Beach Home Apartments, Flat 03', 715, 2, 0, 0, 0, 0, 30, NULL, 1),
(1910, 0, 0, 0, 'Beach Home Apartments, Flat 04', 715, 2, 0, 0, 0, 0, 24, NULL, 1),
(1911, 0, 0, 0, 'Beach Home Apartments, Flat 05', 715, 2, 0, 0, 0, 0, 24, NULL, 1),
(1912, 0, 0, 0, 'Beach Home Apartments, Flat 16', 1145, 2, 0, 0, 0, 0, 40, NULL, 2),
(1913, 0, 0, 0, 'Beach Home Apartments, Flat 11', 715, 2, 0, 0, 0, 0, 30, NULL, 1),
(1914, 0, 0, 0, 'Beach Home Apartments, Flat 12', 880, 2, 0, 0, 0, 0, 30, NULL, 1),
(1915, 0, 0, 0, 'Beach Home Apartments, Flat 13', 880, 2, 0, 0, 0, 0, 29, NULL, 1),
(1916, 0, 0, 0, 'Beach Home Apartments, Flat 14', 385, 2, 0, 0, 0, 0, 15, NULL, 1),
(1917, 0, 0, 0, 'Beach Home Apartments, Flat 15', 385, 2, 0, 0, 0, 0, 15, NULL, 1),
(1918, 0, 0, 0, 'Thais Clanhall', 8420, 2, 0, 0, 0, 0, 370, NULL, 10),
(1919, 0, 0, 0, 'Harbour Street 4', 935, 2, 0, 0, 0, 0, 30, NULL, 1),
(1920, 0, 0, 0, 'Thais Hostel', 6980, 2, 0, 0, 0, 0, 171, NULL, 24),
(1921, 0, 0, 0, 'Lower Swamp Lane 1', 4740, 2, 0, 0, 0, 0, 166, NULL, 4),
(1923, 0, 0, 0, 'Lower Swamp Lane 3', 4740, 2, 0, 0, 0, 0, 161, NULL, 4),
(1924, 0, 0, 0, 'Sunset Homes, Flat 01', 520, 2, 0, 0, 0, 0, 25, NULL, 1),
(1925, 0, 0, 0, 'Sunset Homes, Flat 02', 520, 2, 0, 0, 0, 0, 30, NULL, 1),
(1926, 0, 0, 0, 'Sunset Homes, Flat 03', 520, 2, 0, 0, 0, 0, 30, NULL, 1),
(1927, 0, 0, 0, 'Sunset Homes, Flat 14', 520, 2, 0, 0, 0, 0, 30, NULL, 1),
(1929, 0, 0, 0, 'Sunset Homes, Flat 13', 860, 2, 0, 0, 0, 0, 35, NULL, 2),
(1930, 0, 0, 0, 'Sunset Homes, Flat 12', 520, 2, 0, 0, 0, 0, 25, NULL, 1),
(1932, 0, 0, 0, 'Sunset Homes, Flat 11', 520, 2, 0, 0, 0, 0, 25, NULL, 1),
(1935, 0, 0, 0, 'Sunset Homes, Flat 24', 520, 2, 0, 0, 0, 0, 30, NULL, 1),
(1936, 0, 0, 0, 'Sunset Homes, Flat 23', 860, 2, 0, 0, 0, 0, 35, NULL, 2),
(1937, 0, 0, 0, 'Sunset Homes, Flat 22', 520, 2, 0, 0, 0, 0, 25, NULL, 1),
(1938, 0, 0, 0, 'Sunset Homes, Flat 21', 520, 2, 0, 0, 0, 0, 25, NULL, 1),
(1939, 0, 0, 0, 'Harbour Place 1 (Shop)', 1100, 2, 0, 0, 0, 0, 37, NULL, 1),
(1940, 0, 0, 0, 'Harbour Place 2 (Shop)', 1300, 2, 0, 0, 0, 0, 48, NULL, 1),
(1941, 0, 0, 0, 'Warriors Guildhall', 14725, 2, 0, 0, 0, 0, 522, NULL, 11),
(1942, 0, 0, 0, 'Farm Lane, 1st floor (Shop)', 945, 2, 0, 0, 0, 0, 42, NULL, 0),
(1943, 0, 0, 0, 'Farm Lane, Basement (Shop)', 945, 2, 0, 0, 0, 0, 36, NULL, 0),
(1944, 0, 0, 0, 'Main Street 9, 1st floor (Shop)', 1440, 2, 0, 0, 0, 0, 47, NULL, 0),
(1945, 0, 0, 0, 'Main Street 9a, 2nd floor (Shop)', 765, 2, 0, 0, 0, 0, 30, NULL, 0),
(1946, 0, 0, 0, 'Main Street 9b, 2nd floor (Shop)', 1260, 2, 0, 0, 0, 0, 48, NULL, 0),
(1947, 0, 0, 0, 'Farm Lane, 2nd Floor (Shop)', 945, 2, 0, 0, 0, 0, 42, NULL, 0),
(1948, 0, 0, 0, 'The City Wall 5a', 585, 2, 0, 0, 0, 0, 24, NULL, 1),
(1949, 0, 0, 0, 'The City Wall 5c', 585, 2, 0, 0, 0, 0, 24, NULL, 1),
(1950, 0, 0, 0, 'The City Wall 5e', 585, 2, 0, 0, 0, 0, 30, NULL, 1),
(1951, 0, 0, 0, 'The City Wall 5b', 585, 2, 0, 0, 0, 0, 24, NULL, 1),
(1952, 0, 0, 0, 'The City Wall 5d', 585, 2, 0, 0, 0, 0, 24, NULL, 1),
(1953, 0, 0, 0, 'The City Wall 5f', 585, 2, 0, 0, 0, 0, 30, NULL, 1),
(1954, 0, 0, 0, 'The City Wall 3a', 1045, 2, 0, 0, 0, 0, 42, NULL, 2),
(1955, 0, 0, 0, 'The City Wall 3b', 1045, 2, 0, 0, 0, 0, 35, NULL, 2),
(1956, 0, 0, 0, 'The City Wall 3c', 1045, 2, 0, 0, 0, 0, 35, NULL, 2),
(1957, 0, 0, 0, 'The City Wall 3d', 1045, 2, 0, 0, 0, 0, 41, NULL, 2),
(1958, 0, 0, 0, 'The City Wall 3e', 1045, 2, 0, 0, 0, 0, 30, NULL, 2),
(1959, 0, 0, 0, 'The City Wall 3f', 1045, 2, 0, 0, 0, 0, 31, NULL, 2),
(1960, 0, 0, 0, 'The City Wall 1a', 1270, 2, 0, 0, 0, 0, 49, NULL, 2),
(1961, 0, 0, 0, 'Mill Avenue 3', 1400, 2, 0, 0, 0, 0, 49, NULL, 2),
(1962, 0, 0, 0, 'The City Wall 1b', 1270, 2, 0, 0, 0, 0, 49, NULL, 2),
(1963, 0, 0, 0, 'Mill Avenue 4', 1400, 2, 0, 0, 0, 0, 49, NULL, 2),
(1964, 0, 0, 0, 'Mill Avenue 5', 3250, 2, 0, 0, 0, 0, 128, NULL, 4),
(1965, 0, 0, 0, 'Mill Avenue 1 (Shop)', 1300, 2, 0, 0, 0, 0, 54, NULL, 1),
(1966, 0, 0, 0, 'Mill Avenue 2 (Shop)', 2350, 2, 0, 0, 0, 0, 80, NULL, 2),
(1967, 0, 0, 0, 'The City Wall 7c', 865, 2, 0, 0, 0, 0, 36, NULL, 2),
(1968, 0, 0, 0, 'The City Wall 7a', 585, 2, 0, 0, 0, 0, 30, NULL, 1),
(1969, 0, 0, 0, 'The City Wall 7e', 865, 2, 0, 0, 0, 0, 36, NULL, 2),
(1970, 0, 0, 0, 'The City Wall 7g', 585, 2, 0, 0, 0, 0, 30, NULL, 1),
(1971, 0, 0, 0, 'The City Wall 7d', 865, 2, 0, 0, 0, 0, 36, NULL, 2),
(1972, 0, 0, 0, 'The City Wall 7b', 585, 2, 0, 0, 0, 0, 30, NULL, 1),
(1973, 0, 0, 0, 'The City Wall 7f', 865, 2, 0, 0, 0, 0, 35, NULL, 2),
(1974, 0, 0, 0, 'The City Wall 7h', 585, 2, 0, 0, 0, 0, 30, NULL, 1),
(1975, 0, 0, 0, 'The City Wall 9', 955, 2, 0, 0, 0, 0, 50, NULL, 2),
(1976, 0, 0, 0, 'Upper Swamp Lane 12', 3800, 2, 0, 0, 0, 0, 116, NULL, 3),
(1977, 0, 0, 0, 'Upper Swamp Lane 10', 2060, 2, 0, 0, 0, 0, 70, NULL, 3),
(1978, 0, 0, 0, 'Upper Swamp Lane 8', 8120, 2, 0, 0, 0, 0, 216, NULL, 3),
(1979, 0, 0, 0, 'Southern Thais Guildhall', 22440, 2, 0, 0, 0, 0, 596, NULL, 16),
(1980, 0, 0, 0, 'Alai Flats, Flat 04', 765, 2, 0, 0, 0, 0, 30, NULL, 1),
(1981, 0, 0, 0, 'Alai Flats, Flat 05', 1225, 2, 0, 0, 0, 0, 38, NULL, 2),
(1982, 0, 0, 0, 'Alai Flats, Flat 06', 1225, 2, 0, 0, 0, 0, 48, NULL, 2),
(1983, 0, 0, 0, 'Alai Flats, Flat 07', 765, 2, 0, 0, 0, 0, 30, NULL, 1),
(1984, 0, 0, 0, 'Alai Flats, Flat 08', 765, 2, 0, 0, 0, 0, 30, NULL, 1),
(1985, 0, 0, 0, 'Alai Flats, Flat 03', 765, 2, 0, 0, 0, 0, 36, NULL, 1),
(1986, 0, 0, 0, 'Alai Flats, Flat 01', 765, 2, 0, 0, 0, 0, 26, NULL, 1),
(1987, 0, 0, 0, 'Alai Flats, Flat 02', 765, 2, 0, 0, 0, 0, 34, NULL, 1),
(1988, 0, 0, 0, 'Alai Flats, Flat 14', 900, 2, 0, 0, 0, 0, 33, NULL, 1),
(1989, 0, 0, 0, 'Alai Flats, Flat 15', 1450, 2, 0, 0, 0, 0, 48, NULL, 2),
(1990, 0, 0, 0, 'Alai Flats, Flat 16', 1450, 2, 0, 0, 0, 0, 54, NULL, 2),
(1991, 0, 0, 0, 'Alai Flats, Flat 17', 900, 2, 0, 0, 0, 0, 38, NULL, 1),
(1992, 0, 0, 0, 'Alai Flats, Flat 18', 900, 2, 0, 0, 0, 0, 38, NULL, 1),
(1993, 0, 0, 0, 'Alai Flats, Flat 13', 765, 2, 0, 0, 0, 0, 36, NULL, 1),
(1994, 0, 0, 0, 'Alai Flats, Flat 12', 765, 2, 0, 0, 0, 0, 25, NULL, 1),
(1995, 0, 0, 0, 'Alai Flats, Flat 11', 765, 2, 0, 0, 0, 0, 35, NULL, 1),
(1996, 0, 0, 0, 'Alai Flats, Flat 24', 900, 2, 0, 0, 0, 0, 36, NULL, 1),
(1997, 0, 0, 0, 'Alai Flats, Flat 25', 1450, 2, 0, 0, 0, 0, 52, NULL, 2),
(1998, 0, 0, 0, 'Alai Flats, Flat 26', 1450, 2, 0, 0, 0, 0, 60, NULL, 2),
(1999, 0, 0, 0, 'Alai Flats, Flat 27', 900, 2, 0, 0, 0, 0, 38, NULL, 1),
(2000, 0, 0, 0, 'Alai Flats, Flat 28', 900, 2, 0, 0, 0, 0, 38, NULL, 1),
(2001, 0, 0, 0, 'Alai Flats, Flat 23', 765, 2, 0, 0, 0, 0, 35, NULL, 1),
(2002, 0, 0, 0, 'Alai Flats, Flat 22', 765, 2, 0, 0, 0, 0, 25, NULL, 1),
(2003, 0, 0, 0, 'Alai Flats, Flat 21', 765, 2, 0, 0, 0, 0, 36, NULL, 1),
(2004, 0, 0, 0, 'Upper Swamp Lane 4', 4740, 2, 0, 0, 0, 0, 165, NULL, 4),
(2005, 0, 0, 0, 'Upper Swamp Lane 2', 4740, 2, 0, 0, 0, 0, 159, NULL, 4),
(2006, 0, 0, 0, 'Sorcerer\'s Avenue Labs 2c', 715, 2, 0, 0, 0, 0, 20, NULL, 1),
(2007, 0, 0, 0, 'Sorcerer\'s Avenue Labs 2d', 715, 2, 0, 0, 0, 0, 20, NULL, 1),
(2008, 0, 0, 0, 'Sorcerer\'s Avenue Labs 2e', 715, 2, 0, 0, 0, 0, 20, NULL, 1),
(2009, 0, 0, 0, 'Sorcerer\'s Avenue Labs 2f', 715, 2, 0, 0, 0, 0, 20, NULL, 1),
(2010, 0, 0, 0, 'Sorcerer\'s Avenue Labs 2b', 715, 2, 0, 0, 0, 0, 24, NULL, 1),
(2011, 0, 0, 0, 'Sorcerer\'s Avenue Labs 2a', 715, 2, 0, 0, 0, 0, 24, NULL, 1),
(2012, 0, 0, 0, 'Ivory Circle 1', 4280, 7, 0, 0, 0, 0, 160, NULL, 2),
(2013, 0, 0, 0, 'Admiral\'s Avenue 3', 4115, 7, 0, 0, 0, 0, 142, NULL, 2),
(2014, 0, 0, 0, 'Admiral\'s Avenue 2', 5470, 7, 0, 0, 0, 0, 176, NULL, 4),
(2015, 0, 0, 0, 'Admiral\'s Avenue 1', 5105, 7, 0, 0, 0, 0, 168, NULL, 2),
(2016, 0, 0, 0, 'Sugar Street 5', 1350, 7, 0, 0, 0, 0, 48, NULL, 2),
(2017, 0, 0, 0, 'Freedom Street 1', 2450, 7, 0, 0, 0, 0, 84, NULL, 2),
(2018, 0, 0, 0, 'Freedom Street 2', 6050, 7, 0, 0, 0, 0, 208, NULL, 4),
(2019, 0, 0, 0, 'Trader\'s Point 2 (Shop)', 5350, 7, 0, 0, 0, 0, 198, NULL, 2),
(2020, 0, 0, 0, 'Trader\'s Point 3 (Shop)', 5950, 7, 0, 0, 0, 0, 195, NULL, 2),
(2021, 0, 0, 0, 'Ivory Circle 2', 7030, 7, 0, 0, 0, 0, 214, NULL, 2),
(2022, 0, 0, 0, 'The Tavern 1a', 2750, 7, 0, 0, 0, 0, 72, NULL, 4),
(2023, 0, 0, 0, 'The Tavern 1b', 1900, 7, 0, 0, 0, 0, 54, NULL, 2),
(2024, 0, 0, 0, 'The Tavern 1c', 4150, 7, 0, 0, 0, 0, 132, NULL, 3),
(2025, 0, 0, 0, 'The Tavern 1d', 1550, 7, 0, 0, 0, 0, 48, NULL, 2),
(2026, 0, 0, 0, 'The Tavern 2d', 1350, 7, 0, 0, 0, 0, 40, NULL, 2),
(2027, 0, 0, 0, 'The Tavern 2c', 950, 7, 0, 0, 0, 0, 32, NULL, 1),
(2028, 0, 0, 0, 'The Tavern 2b', 1700, 7, 0, 0, 0, 0, 62, NULL, 2),
(2029, 0, 0, 0, 'The Tavern 2a', 5550, 7, 0, 0, 0, 0, 163, NULL, 5),
(2030, 0, 0, 0, 'Straycat\'s Corner 4', 210, 7, 0, 0, 0, 0, 20, NULL, 1),
(2031, 0, 0, 0, 'Straycat\'s Corner 3', 210, 7, 0, 0, 0, 0, 20, NULL, 1),
(2032, 0, 0, 0, 'Straycat\'s Corner 2', 660, 7, 0, 0, 0, 0, 49, NULL, 1),
(2033, 0, 0, 0, 'Litter Promenade 5', 580, 7, 0, 0, 0, 0, 35, NULL, 2),
(2034, 0, 0, 0, 'Litter Promenade 4', 390, 7, 0, 0, 0, 0, 30, NULL, 1),
(2035, 0, 0, 0, 'Litter Promenade 3', 450, 7, 0, 0, 0, 0, 36, NULL, 1),
(2036, 0, 0, 0, 'Litter Promenade 2', 300, 7, 0, 0, 0, 0, 25, NULL, 1),
(2037, 0, 0, 0, 'Litter Promenade 1', 400, 7, 0, 0, 0, 0, 25, NULL, 2),
(2038, 0, 0, 0, 'The Shelter', 13590, 7, 0, 0, 0, 0, 560, NULL, 31),
(2039, 0, 0, 0, 'Straycat\'s Corner 6', 300, 7, 0, 0, 0, 0, 25, NULL, 1),
(2040, 0, 0, 0, 'Straycat\'s Corner 5', 760, 7, 0, 0, 0, 0, 48, NULL, 2),
(2042, 0, 0, 0, 'Rum Alley 3', 330, 7, 0, 0, 0, 0, 28, NULL, 1),
(2043, 0, 0, 0, 'Straycat\'s Corner 1', 300, 7, 0, 0, 0, 0, 25, NULL, 1),
(2044, 0, 0, 0, 'Rum Alley 2', 300, 7, 0, 0, 0, 0, 25, NULL, 1),
(2045, 0, 0, 0, 'Rum Alley 1', 510, 7, 0, 0, 0, 0, 36, NULL, 1),
(2046, 0, 0, 0, 'Smuggler Backyard 3', 700, 7, 0, 0, 0, 0, 40, NULL, 2),
(2048, 0, 0, 0, 'Shady Trail 3', 300, 7, 0, 0, 0, 0, 25, NULL, 1),
(2049, 0, 0, 0, 'Shady Trail 1', 1150, 7, 0, 0, 0, 0, 48, NULL, 5),
(2050, 0, 0, 0, 'Shady Trail 2', 490, 7, 0, 0, 0, 0, 30, NULL, 2),
(2051, 0, 0, 0, 'Smuggler Backyard 5', 610, 7, 0, 0, 0, 0, 35, NULL, 2),
(2052, 0, 0, 0, 'Smuggler Backyard 4', 390, 7, 0, 0, 0, 0, 30, NULL, 1),
(2053, 0, 0, 0, 'Smuggler Backyard 2', 670, 7, 0, 0, 0, 0, 40, NULL, 2),
(2054, 0, 0, 0, 'Smuggler Backyard 1', 670, 7, 0, 0, 0, 0, 40, NULL, 2),
(2055, 0, 0, 0, 'Sugar Street 2', 2550, 7, 0, 0, 0, 0, 84, NULL, 3),
(2056, 0, 0, 0, 'Sugar Street 1', 3000, 7, 0, 0, 0, 0, 84, NULL, 3),
(2057, 0, 0, 0, 'Sugar Street 3a', 1650, 7, 0, 0, 0, 0, 54, NULL, 3),
(2058, 0, 0, 0, 'Sugar Street 3b', 2050, 7, 0, 0, 0, 0, 60, NULL, 3),
(2059, 0, 0, 0, 'Harvester\'s Haven, Flat 01', 950, 7, 0, 0, 0, 0, 36, NULL, 2),
(2060, 0, 0, 0, 'Harvester\'s Haven, Flat 03', 950, 7, 0, 0, 0, 0, 30, NULL, 2),
(2061, 0, 0, 0, 'Harvester\'s Haven, Flat 05', 950, 7, 0, 0, 0, 0, 30, NULL, 2),
(2062, 0, 0, 0, 'Harvester\'s Haven, Flat 02', 950, 7, 0, 0, 0, 0, 36, NULL, 2),
(2063, 0, 0, 0, 'Harvester\'s Haven, Flat 04', 950, 7, 0, 0, 0, 0, 30, NULL, 2),
(2064, 0, 0, 0, 'Harvester\'s Haven, Flat 06', 950, 7, 0, 0, 0, 0, 30, NULL, 2),
(2065, 0, 0, 0, 'Harvester\'s Haven, Flat 07', 950, 7, 0, 0, 0, 0, 30, NULL, 2),
(2066, 0, 0, 0, 'Harvester\'s Haven, Flat 09', 950, 7, 0, 0, 0, 0, 30, NULL, 2),
(2067, 0, 0, 0, 'Harvester\'s Haven, Flat 11', 950, 7, 0, 0, 0, 0, 36, NULL, 2),
(2068, 0, 0, 0, 'Harvester\'s Haven, Flat 12', 950, 7, 0, 0, 0, 0, 36, NULL, 2),
(2069, 0, 0, 0, 'Harvester\'s Haven, Flat 10', 950, 7, 0, 0, 0, 0, 30, NULL, 2),
(2070, 0, 0, 0, 'Harvester\'s Haven, Flat 08', 950, 7, 0, 0, 0, 0, 30, NULL, 2),
(2071, 0, 0, 0, 'Marble Lane 4', 6350, 7, 0, 0, 0, 0, 192, NULL, 4),
(2072, 0, 0, 0, 'Marble Lane 2', 6415, 7, 0, 0, 0, 0, 200, NULL, 3),
(2073, 0, 0, 0, 'Marble Lane 3', 8055, 7, 0, 0, 0, 0, 240, NULL, 4),
(2074, 0, 0, 0, 'Marble Lane 1', 11060, 7, 0, 0, 0, 0, 320, NULL, 6),
(2075, 0, 0, 0, 'Ivy Cottage', 30650, 7, 0, 0, 0, 0, 858, NULL, 26),
(2076, 0, 0, 0, 'Sugar Street 4d', 750, 7, 0, 0, 0, 0, 24, NULL, 2),
(2077, 0, 0, 0, 'Sugar Street 4c', 650, 7, 0, 0, 0, 0, 24, NULL, 1),
(2078, 0, 0, 0, 'Sugar Street 4b', 950, 7, 0, 0, 0, 0, 36, NULL, 2),
(2079, 0, 0, 0, 'Sugar Street 4a', 950, 7, 0, 0, 0, 0, 30, NULL, 2),
(2080, 0, 0, 0, 'Trader\'s Point 1', 2200, 7, 0, 0, 0, 0, 77, NULL, 2),
(2081, 0, 0, 0, 'Mountain Hideout', 15550, 7, 0, 0, 0, 0, 486, NULL, 17),
(2082, 0, 0, 0, 'Dark Mansion', 17845, 2, 0, 0, 0, 0, 575, NULL, 17),
(2083, 0, 0, 0, 'Halls of the Adventurers', 15380, 2, 0, 0, 0, 0, 518, NULL, 18),
(2084, 0, 0, 0, 'Castle of Greenshore', 18860, 2, 0, 0, 0, 0, 600, NULL, 12),
(2085, 0, 0, 0, 'Greenshore Clanhall', 10800, 2, 0, 0, 0, 0, 312, NULL, 10),
(2086, 0, 0, 0, 'Greenshore Village 1', 2420, 2, 0, 0, 0, 0, 64, NULL, 3),
(2087, 0, 0, 0, 'Greenshore Village, Shop', 1800, 2, 0, 0, 0, 0, 56, NULL, 1),
(2088, 0, 0, 0, 'Greenshore Village, Villa', 8700, 2, 0, 0, 0, 0, 263, NULL, 4),
(2089, 0, 0, 0, 'Greenshore Village 2', 780, 2, 0, 0, 0, 0, 30, NULL, 1),
(2090, 0, 0, 0, 'Greenshore Village 3', 780, 2, 0, 0, 0, 0, 25, NULL, 1),
(2091, 0, 0, 0, 'Greenshore Village 5', 780, 2, 0, 0, 0, 0, 30, NULL, 1),
(2092, 0, 0, 0, 'Greenshore Village 4', 780, 2, 0, 0, 0, 0, 25, NULL, 1),
(2093, 0, 0, 0, 'Greenshore Village 6', 4360, 2, 0, 0, 0, 0, 118, NULL, 2),
(2094, 0, 0, 0, 'Greenshore Village 7', 1260, 2, 0, 0, 0, 0, 42, NULL, 1),
(2095, 0, 0, 0, 'The Tibianic', 34500, 2, 0, 0, 0, 0, 862, NULL, 22),
(2097, 0, 0, 0, 'Fibula Village 5', 1790, 2, 0, 0, 0, 0, 42, NULL, 2),
(2098, 0, 0, 0, 'Fibula Village 4', 1790, 2, 0, 0, 0, 0, 42, NULL, 2),
(2099, 0, 0, 0, 'Fibula Village, Tower Flat', 5105, 2, 0, 0, 0, 0, 161, NULL, 2),
(2100, 0, 0, 0, 'Fibula Village 1', 845, 2, 0, 0, 0, 0, 30, NULL, 1),
(2101, 0, 0, 0, 'Fibula Village 2', 845, 2, 0, 0, 0, 0, 30, NULL, 1),
(2102, 0, 0, 0, 'Fibula Village 3', 3810, 2, 0, 0, 0, 0, 110, NULL, 4),
(2103, 0, 0, 0, 'Mercenary Tower', 41955, 2, 0, 0, 0, 0, 996, NULL, 26),
(2104, 0, 0, 0, 'Guildhall of the Red Rose', 27725, 2, 0, 0, 0, 0, 571, NULL, 15),
(2105, 0, 0, 0, 'Fibula Village, Bar', 5235, 2, 0, 0, 0, 0, 122, NULL, 2),
(2106, 0, 0, 0, 'Fibula Village, Villa', 11490, 2, 0, 0, 0, 0, 402, NULL, 5),
(2107, 0, 0, 0, 'Fibula Clanhall', 11430, 2, 0, 0, 0, 0, 290, NULL, 10),
(2108, 0, 0, 0, 'Spiritkeep', 19210, 2, 0, 0, 0, 0, 783, NULL, 23),
(2109, 0, 0, 0, 'Snake Tower', 29720, 2, 0, 0, 0, 0, 1064, NULL, 21),
(2110, 0, 0, 0, 'Bloodhall', 15270, 2, 0, 0, 0, 0, 569, NULL, 15),
(2111, 0, 0, 0, 'Senja Clanhall', 10575, 4, 0, 0, 0, 0, 396, NULL, 9),
(2112, 0, 0, 0, 'Senja Village 2', 765, 4, 0, 0, 0, 0, 36, NULL, 1),
(2113, 0, 0, 0, 'Senja Village 1a', 765, 4, 0, 0, 0, 0, 36, NULL, 1),
(2114, 0, 0, 0, 'Senja Village 1b', 1630, 4, 0, 0, 0, 0, 66, NULL, 2),
(2115, 0, 0, 0, 'Senja Village 4', 765, 4, 0, 0, 0, 0, 30, NULL, 1),
(2116, 0, 0, 0, 'Senja Village 3', 1765, 4, 0, 0, 0, 0, 72, NULL, 2),
(2117, 0, 0, 0, 'Senja Village 6b', 765, 4, 0, 0, 0, 0, 30, NULL, 1);
INSERT INTO `houses` (`id`, `owner`, `paid`, `warnings`, `name`, `rent`, `town_id`, `bid`, `bid_end`, `last_bid`, `highest_bidder`, `size`, `guildid`, `beds`) VALUES
(2118, 0, 0, 0, 'Senja Village 6a', 765, 4, 0, 0, 0, 0, 30, NULL, 1),
(2119, 0, 0, 0, 'Senja Village 5', 1225, 4, 0, 0, 0, 0, 48, NULL, 2),
(2120, 0, 0, 0, 'Senja Village 10', 1485, 4, 0, 0, 0, 0, 72, NULL, 1),
(2121, 0, 0, 0, 'Senja Village 11', 2620, 4, 0, 0, 0, 0, 96, NULL, 2),
(2122, 0, 0, 0, 'Senja Village 9', 2575, 4, 0, 0, 0, 0, 103, NULL, 2),
(2123, 0, 0, 0, 'Senja Village 8', 1675, 4, 0, 0, 0, 0, 57, NULL, 2),
(2124, 0, 0, 0, 'Senja Village 7', 865, 4, 0, 0, 0, 0, 37, NULL, 2),
(2125, 0, 0, 0, 'Rosebud C', 1340, 4, 0, 0, 0, 0, 70, NULL, 0),
(2127, 0, 0, 0, 'Rosebud A', 1000, 4, 0, 0, 0, 0, 60, NULL, 1),
(2128, 0, 0, 0, 'Rosebud B', 1000, 4, 0, 0, 0, 0, 60, NULL, 1),
(2129, 0, 0, 0, 'Nordic Stronghold', 18400, 4, 0, 0, 0, 0, 718, NULL, 21),
(2130, 0, 0, 0, 'Northport Village 2', 1475, 4, 0, 0, 0, 0, 40, NULL, 2),
(2131, 0, 0, 0, 'Northport Village 1', 1475, 4, 0, 0, 0, 0, 48, NULL, 2),
(2132, 0, 0, 0, 'Northport Village 3', 5435, 4, 0, 0, 0, 0, 178, NULL, 2),
(2133, 0, 0, 0, 'Northport Village 4', 2630, 4, 0, 0, 0, 0, 81, NULL, 2),
(2134, 0, 0, 0, 'Northport Village 5', 1805, 4, 0, 0, 0, 0, 56, NULL, 2),
(2135, 0, 0, 0, 'Northport Village 6', 2135, 4, 0, 0, 0, 0, 64, NULL, 2),
(2136, 0, 0, 0, 'Seawatch', 25010, 4, 0, 0, 0, 0, 749, NULL, 19),
(2137, 0, 0, 0, 'Northport Clanhall', 9810, 4, 0, 0, 0, 0, 292, NULL, 10),
(2138, 0, 0, 0, 'Druids Retreat D', 1180, 4, 0, 0, 0, 0, 54, NULL, 2),
(2139, 0, 0, 0, 'Druids Retreat A', 1340, 4, 0, 0, 0, 0, 60, NULL, 2),
(2140, 0, 0, 0, 'Druids Retreat C', 980, 4, 0, 0, 0, 0, 45, NULL, 2),
(2141, 0, 0, 0, 'Druids Retreat B', 980, 4, 0, 0, 0, 0, 55, NULL, 2),
(2142, 0, 0, 0, 'Theater Avenue 14 (Shop)', 2115, 4, 0, 0, 0, 0, 83, NULL, 1),
(2143, 0, 0, 0, 'Theater Avenue 12', 955, 4, 0, 0, 0, 0, 28, NULL, 2),
(2144, 0, 0, 0, 'Theater Avenue 10', 1090, 4, 0, 0, 0, 0, 45, NULL, 2),
(2145, 0, 0, 0, 'Theater Avenue 11c', 585, 4, 0, 0, 0, 0, 24, NULL, 1),
(2146, 0, 0, 0, 'Theater Avenue 11b', 585, 4, 0, 0, 0, 0, 24, NULL, 1),
(2147, 0, 0, 0, 'Theater Avenue 11a', 1405, 4, 0, 0, 0, 0, 54, NULL, 2),
(2148, 0, 0, 0, 'Magician\'s Alley 1', 1050, 4, 0, 0, 0, 0, 35, NULL, 2),
(2149, 0, 0, 0, 'Magician\'s Alley 1a', 700, 4, 0, 0, 0, 0, 29, NULL, 2),
(2150, 0, 0, 0, 'Magician\'s Alley 1d', 450, 4, 0, 0, 0, 0, 24, NULL, 1),
(2151, 0, 0, 0, 'Magician\'s Alley 1b', 750, 4, 0, 0, 0, 0, 24, NULL, 2),
(2152, 0, 0, 0, 'Magician\'s Alley 1c', 500, 4, 0, 0, 0, 0, 20, NULL, 1),
(2153, 0, 0, 0, 'Magician\'s Alley 5a', 350, 4, 0, 0, 0, 0, 14, NULL, 1),
(2154, 0, 0, 0, 'Magician\'s Alley 5b', 500, 4, 0, 0, 0, 0, 25, NULL, 1),
(2155, 0, 0, 0, 'Magician\'s Alley 5d', 500, 4, 0, 0, 0, 0, 20, NULL, 1),
(2156, 0, 0, 0, 'Magician\'s Alley 5e', 500, 4, 0, 0, 0, 0, 25, NULL, 1),
(2157, 0, 0, 0, 'Magician\'s Alley 5c', 1150, 4, 0, 0, 0, 0, 35, NULL, 2),
(2158, 0, 0, 0, 'Magician\'s Alley 5f', 1150, 4, 0, 0, 0, 0, 42, NULL, 2),
(2159, 0, 0, 0, 'Carlin Clanhall', 10750, 4, 0, 0, 0, 0, 364, NULL, 10),
(2160, 0, 0, 0, 'Magician\'s Alley 4', 2750, 4, 0, 0, 0, 0, 96, NULL, 4),
(2161, 0, 0, 0, 'Lonely Sea Side Hostel', 10540, 4, 0, 0, 0, 0, 454, NULL, 8),
(2162, 0, 0, 0, 'Suntower', 10080, 4, 0, 0, 0, 0, 450, NULL, 7),
(2163, 0, 0, 0, 'Harbour Lane 3', 3560, 4, 0, 0, 0, 0, 145, NULL, 3),
(2164, 0, 0, 0, 'Harbour Flats, Flat 11', 520, 4, 0, 0, 0, 0, 24, NULL, 1),
(2165, 0, 0, 0, 'Harbour Flats, Flat 13', 520, 4, 0, 0, 0, 0, 24, NULL, 1),
(2166, 0, 0, 0, 'Harbour Flats, Flat 15', 360, 4, 0, 0, 0, 0, 18, NULL, 1),
(2167, 0, 0, 0, 'Harbour Flats, Flat 17', 360, 4, 0, 0, 0, 0, 24, NULL, 1),
(2168, 0, 0, 0, 'Harbour Flats, Flat 12', 400, 4, 0, 0, 0, 0, 20, NULL, 1),
(2169, 0, 0, 0, 'Harbour Flats, Flat 14', 400, 4, 0, 0, 0, 0, 20, NULL, 1),
(2170, 0, 0, 0, 'Harbour Flats, Flat 16', 400, 4, 0, 0, 0, 0, 20, NULL, 1),
(2171, 0, 0, 0, 'Harbour Flats, Flat 18', 400, 4, 0, 0, 0, 0, 25, NULL, 1),
(2172, 0, 0, 0, 'Harbour Flats, Flat 21', 860, 4, 0, 0, 0, 0, 35, NULL, 2),
(2173, 0, 0, 0, 'Harbour Flats, Flat 22', 980, 4, 0, 0, 0, 0, 45, NULL, 2),
(2174, 0, 0, 0, 'Harbour Flats, Flat 23', 400, 4, 0, 0, 0, 0, 25, NULL, 1),
(2175, 0, 0, 0, 'Harbour Lane 2a (Shop)', 680, 4, 0, 0, 0, 0, 32, NULL, 0),
(2176, 0, 0, 0, 'Harbour Lane 2b (Shop)', 680, 4, 0, 0, 0, 0, 40, NULL, 0),
(2177, 0, 0, 0, 'Harbour Lane 1 (Shop)', 1040, 4, 0, 0, 0, 0, 54, NULL, 0),
(2178, 0, 0, 0, 'Theater Avenue 6e', 820, 4, 0, 0, 0, 0, 31, NULL, 2),
(2179, 0, 0, 0, 'Theater Avenue 6c', 225, 4, 0, 0, 0, 0, 12, NULL, 1),
(2180, 0, 0, 0, 'Theater Avenue 6a', 820, 4, 0, 0, 0, 0, 35, NULL, 2),
(2181, 0, 0, 0, 'Theater Avenue 6f', 820, 4, 0, 0, 0, 0, 31, NULL, 2),
(2182, 0, 0, 0, 'Theater Avenue 6d', 225, 4, 0, 0, 0, 0, 12, NULL, 1),
(2183, 0, 0, 0, 'Theater Avenue 6b', 820, 4, 0, 0, 0, 0, 35, NULL, 2),
(2184, 0, 0, 0, 'East Lane 1a', 2260, 4, 0, 0, 0, 0, 95, NULL, 2),
(2185, 0, 0, 0, 'East Lane 1b', 1700, 4, 0, 0, 0, 0, 83, NULL, 2),
(2186, 0, 0, 0, 'East Lane 2', 3900, 4, 0, 0, 0, 0, 172, NULL, 2),
(2191, 0, 0, 0, 'Northern Street 5', 1980, 4, 0, 0, 0, 0, 94, NULL, 2),
(2192, 0, 0, 0, 'Northern Street 7', 1700, 4, 0, 0, 0, 0, 83, NULL, 2),
(2193, 0, 0, 0, 'Northern Street 3a', 740, 4, 0, 0, 0, 0, 31, NULL, 2),
(2194, 0, 0, 0, 'Northern Street 3b', 780, 4, 0, 0, 0, 0, 36, NULL, 2),
(2195, 0, 0, 0, 'Northern Street 1c', 740, 4, 0, 0, 0, 0, 31, NULL, 2),
(2196, 0, 0, 0, 'Northern Street 1b', 740, 4, 0, 0, 0, 0, 37, NULL, 2),
(2197, 0, 0, 0, 'Northern Street 1a', 940, 4, 0, 0, 0, 0, 41, NULL, 2),
(2198, 0, 0, 0, 'Theater Avenue 7, Flat 06', 315, 4, 0, 0, 0, 0, 20, NULL, 1),
(2199, 0, 0, 0, 'Theater Avenue 7, Flat 01', 315, 4, 0, 0, 0, 0, 15, NULL, 1),
(2200, 0, 0, 0, 'Theater Avenue 7, Flat 05', 405, 4, 0, 0, 0, 0, 20, NULL, 1),
(2201, 0, 0, 0, 'Theater Avenue 7, Flat 02', 405, 4, 0, 0, 0, 0, 20, NULL, 1),
(2202, 0, 0, 0, 'Theater Avenue 7, Flat 04', 495, 4, 0, 0, 0, 0, 20, NULL, 1),
(2203, 0, 0, 0, 'Theater Avenue 7, Flat 03', 405, 4, 0, 0, 0, 0, 19, NULL, 1),
(2204, 0, 0, 0, 'Theater Avenue 7, Flat 14', 495, 4, 0, 0, 0, 0, 20, NULL, 1),
(2205, 0, 0, 0, 'Theater Avenue 7, Flat 13', 405, 4, 0, 0, 0, 0, 17, NULL, 1),
(2206, 0, 0, 0, 'Theater Avenue 7, Flat 15', 405, 4, 0, 0, 0, 0, 19, NULL, 1),
(2207, 0, 0, 0, 'Theater Avenue 7, Flat 16', 405, 4, 0, 0, 0, 0, 20, NULL, 1),
(2208, 0, 0, 0, 'Theater Avenue 7, Flat 11', 495, 4, 0, 0, 0, 0, 23, NULL, 1),
(2209, 0, 0, 0, 'Theater Avenue 7, Flat 12', 405, 4, 0, 0, 0, 0, 15, NULL, 1),
(2210, 0, 0, 0, 'Theater Avenue 8a', 1270, 4, 0, 0, 0, 0, 50, NULL, 2),
(2211, 0, 0, 0, 'Theater Avenue 8b', 1370, 4, 0, 0, 0, 0, 49, NULL, 3),
(2212, 0, 0, 0, 'Central Plaza 3', 600, 4, 0, 0, 0, 0, 20, NULL, 0),
(2213, 0, 0, 0, 'Central Plaza 2', 600, 4, 0, 0, 0, 0, 20, NULL, 0),
(2214, 0, 0, 0, 'Central Plaza 1', 600, 4, 0, 0, 0, 0, 24, NULL, 0),
(2215, 0, 0, 0, 'Park Lane 1a', 1220, 4, 0, 0, 0, 0, 53, NULL, 2),
(2216, 0, 0, 0, 'Park Lane 3a', 1220, 4, 0, 0, 0, 0, 48, NULL, 2),
(2217, 0, 0, 0, 'Park Lane 1b', 1380, 4, 0, 0, 0, 0, 64, NULL, 2),
(2218, 0, 0, 0, 'Park Lane 3b', 1100, 4, 0, 0, 0, 0, 48, NULL, 2),
(2219, 0, 0, 0, 'Park Lane 4', 980, 4, 0, 0, 0, 0, 42, NULL, 2),
(2220, 0, 0, 0, 'Park Lane 2', 980, 4, 0, 0, 0, 0, 42, NULL, 2),
(2221, 0, 0, 0, 'Magician\'s Alley 8', 1400, 4, 0, 0, 0, 0, 42, NULL, 2),
(2222, 0, 0, 0, 'Moonkeep', 13020, 4, 0, 0, 0, 0, 522, NULL, 16),
(2225, 0, 0, 0, 'Castle, Basement, Flat 01', 585, 11, 0, 0, 0, 0, 30, NULL, 1),
(2226, 0, 0, 0, 'Castle, Basement, Flat 02', 585, 11, 0, 0, 0, 0, 20, NULL, 1),
(2227, 0, 0, 0, 'Castle, Basement, Flat 03', 585, 11, 0, 0, 0, 0, 20, NULL, 1),
(2228, 0, 0, 0, 'Castle, Basement, Flat 04', 585, 11, 0, 0, 0, 0, 20, NULL, 1),
(2229, 0, 0, 0, 'Castle, Basement, Flat 07', 585, 11, 0, 0, 0, 0, 20, NULL, 1),
(2230, 0, 0, 0, 'Castle, Basement, Flat 08', 585, 11, 0, 0, 0, 0, 20, NULL, 1),
(2231, 0, 0, 0, 'Castle, Basement, Flat 09', 585, 11, 0, 0, 0, 0, 24, NULL, 1),
(2232, 0, 0, 0, 'Castle, Basement, Flat 06', 585, 11, 0, 0, 0, 0, 24, NULL, 1),
(2233, 0, 0, 0, 'Castle, Basement, Flat 05', 585, 11, 0, 0, 0, 0, 24, NULL, 1),
(2234, 0, 0, 0, 'Castle Shop 1', 1890, 11, 0, 0, 0, 0, 67, NULL, 1),
(2235, 0, 0, 0, 'Castle Shop 2', 1890, 11, 0, 0, 0, 0, 70, NULL, 1),
(2236, 0, 0, 0, 'Castle Shop 3', 1890, 11, 0, 0, 0, 0, 67, NULL, 1),
(2237, 0, 0, 0, 'Castle, 4th Floor, Flat 09', 720, 11, 0, 0, 0, 0, 28, NULL, 1),
(2238, 0, 0, 0, 'Castle, 4th Floor, Flat 08', 945, 11, 0, 0, 0, 0, 42, NULL, 1),
(2239, 0, 0, 0, 'Castle, 4th Floor, Flat 06', 945, 11, 0, 0, 0, 0, 36, NULL, 1),
(2240, 0, 0, 0, 'Castle, 4th Floor, Flat 07', 720, 11, 0, 0, 0, 0, 30, NULL, 1),
(2241, 0, 0, 0, 'Castle, 4th Floor, Flat 05', 765, 11, 0, 0, 0, 0, 30, NULL, 1),
(2242, 0, 0, 0, 'Castle, 4th Floor, Flat 04', 585, 11, 0, 0, 0, 0, 25, NULL, 1),
(2243, 0, 0, 0, 'Castle, 4th Floor, Flat 03', 585, 11, 0, 0, 0, 0, 30, NULL, 1),
(2244, 0, 0, 0, 'Castle, 4th Floor, Flat 02', 765, 11, 0, 0, 0, 0, 30, NULL, 1),
(2245, 0, 0, 0, 'Castle, 4th Floor, Flat 01', 585, 11, 0, 0, 0, 0, 30, NULL, 1),
(2246, 0, 0, 0, 'Castle, 3rd Floor, Flat 01', 585, 11, 0, 0, 0, 0, 30, NULL, 1),
(2247, 0, 0, 0, 'Castle, 3rd Floor, Flat 02', 765, 11, 0, 0, 0, 0, 30, NULL, 1),
(2248, 0, 0, 0, 'Castle, 3rd Floor, Flat 03', 585, 11, 0, 0, 0, 0, 25, NULL, 1),
(2249, 0, 0, 0, 'Castle, 3rd Floor, Flat 05', 765, 11, 0, 0, 0, 0, 30, NULL, 1),
(2250, 0, 0, 0, 'Castle, 3rd Floor, Flat 04', 585, 11, 0, 0, 0, 0, 25, NULL, 1),
(2251, 0, 0, 0, 'Castle, 3rd Floor, Flat 06', 1045, 11, 0, 0, 0, 0, 36, NULL, 2),
(2252, 0, 0, 0, 'Castle, 3rd Floor, Flat 07', 720, 11, 0, 0, 0, 0, 30, NULL, 1),
(2253, 0, 0, 0, 'Castle Street 1', 2900, 11, 0, 0, 0, 0, 112, NULL, 3),
(2254, 0, 0, 0, 'Castle Street 2', 1495, 11, 0, 0, 0, 0, 56, NULL, 2),
(2255, 0, 0, 0, 'Castle Street 3', 1765, 11, 0, 0, 0, 0, 56, NULL, 2),
(2256, 0, 0, 0, 'Castle Street 4', 1765, 11, 0, 0, 0, 0, 64, NULL, 2),
(2257, 0, 0, 0, 'Castle Street 5', 1765, 11, 0, 0, 0, 0, 61, NULL, 2),
(2258, 0, 0, 0, 'Edron Flats, Basement Flat 2', 1540, 11, 0, 0, 0, 0, 48, NULL, 2),
(2259, 0, 0, 0, 'Edron Flats, Basement Flat 1', 1540, 11, 0, 0, 0, 0, 48, NULL, 2),
(2260, 0, 0, 0, 'Edron Flats, Flat 01', 400, 11, 0, 0, 0, 0, 20, NULL, 1),
(2261, 0, 0, 0, 'Edron Flats, Flat 02', 860, 11, 0, 0, 0, 0, 28, NULL, 2),
(2262, 0, 0, 0, 'Edron Flats, Flat 03', 400, 11, 0, 0, 0, 0, 20, NULL, 1),
(2263, 0, 0, 0, 'Edron Flats, Flat 04', 400, 11, 0, 0, 0, 0, 20, NULL, 1),
(2264, 0, 0, 0, 'Edron Flats, Flat 06', 400, 11, 0, 0, 0, 0, 20, NULL, 1),
(2265, 0, 0, 0, 'Edron Flats, Flat 05', 400, 11, 0, 0, 0, 0, 20, NULL, 1),
(2266, 0, 0, 0, 'Edron Flats, Flat 07', 400, 11, 0, 0, 0, 0, 20, NULL, 1),
(2267, 0, 0, 0, 'Edron Flats, Flat 08', 400, 11, 0, 0, 0, 0, 20, NULL, 1),
(2268, 0, 0, 0, 'Edron Flats, Flat 11', 400, 11, 0, 0, 0, 0, 25, NULL, 1),
(2269, 0, 0, 0, 'Edron Flats, Flat 12', 400, 11, 0, 0, 0, 0, 25, NULL, 1),
(2270, 0, 0, 0, 'Edron Flats, Flat 14', 400, 11, 0, 0, 0, 0, 25, NULL, 1),
(2271, 0, 0, 0, 'Edron Flats, Flat 13', 400, 11, 0, 0, 0, 0, 25, NULL, 1),
(2272, 0, 0, 0, 'Edron Flats, Flat 16', 400, 11, 0, 0, 0, 0, 20, NULL, 1),
(2273, 0, 0, 0, 'Edron Flats, Flat 15', 400, 11, 0, 0, 0, 0, 20, NULL, 1),
(2274, 0, 0, 0, 'Edron Flats, Flat 18', 400, 11, 0, 0, 0, 0, 20, NULL, 1),
(2275, 0, 0, 0, 'Edron Flats, Flat 17', 400, 11, 0, 0, 0, 0, 20, NULL, 1),
(2276, 0, 0, 0, 'Edron Flats, Flat 22', 400, 11, 0, 0, 0, 0, 25, NULL, 1),
(2277, 0, 0, 0, 'Edron Flats, Flat 21', 860, 11, 0, 0, 0, 0, 40, NULL, 2),
(2278, 0, 0, 0, 'Edron Flats, Flat 24', 400, 11, 0, 0, 0, 0, 20, NULL, 1),
(2279, 0, 0, 0, 'Edron Flats, Flat 23', 400, 11, 0, 0, 0, 0, 25, NULL, 1),
(2280, 0, 0, 0, 'Edron Flats, Flat 26', 400, 11, 0, 0, 0, 0, 20, NULL, 1),
(2281, 0, 0, 0, 'Edron Flats, Flat 27', 400, 11, 0, 0, 0, 0, 20, NULL, 1),
(2282, 0, 0, 0, 'Edron Flats, Flat 28', 400, 11, 0, 0, 0, 0, 20, NULL, 1),
(2283, 0, 0, 0, 'Edron Flats, Flat 25', 400, 11, 0, 0, 0, 0, 20, NULL, 1),
(2284, 0, 0, 0, 'Central Circle 1', 3020, 11, 0, 0, 0, 0, 119, NULL, 2),
(2285, 0, 0, 0, 'Central Circle 2', 3300, 11, 0, 0, 0, 0, 109, NULL, 2),
(2286, 0, 0, 0, 'Central Circle 3', 4160, 11, 0, 0, 0, 0, 147, NULL, 5),
(2287, 0, 0, 0, 'Central Circle 4', 4160, 11, 0, 0, 0, 0, 147, NULL, 5),
(2288, 0, 0, 0, 'Central Circle 5', 4160, 11, 0, 0, 0, 0, 161, NULL, 5),
(2289, 0, 0, 0, 'Central Circle 6 (Shop)', 3980, 11, 0, 0, 0, 0, 182, NULL, 2),
(2290, 0, 0, 0, 'Central Circle 7 (Shop)', 3980, 11, 0, 0, 0, 0, 161, NULL, 2),
(2291, 0, 0, 0, 'Central Circle 8 (Shop)', 3980, 11, 0, 0, 0, 0, 166, NULL, 2),
(2292, 0, 0, 0, 'Central Circle 9a', 940, 11, 0, 0, 0, 0, 42, NULL, 2),
(2293, 0, 0, 0, 'Central Circle 9b', 940, 11, 0, 0, 0, 0, 44, NULL, 2),
(2294, 0, 0, 0, 'Sky Lane, Guild 1', 21145, 11, 0, 0, 0, 0, 666, NULL, 23),
(2295, 0, 0, 0, 'Sky Lane, Guild 2', 19300, 11, 0, 0, 0, 0, 672, NULL, 14),
(2296, 0, 0, 0, 'Sky Lane, Guild 3', 17315, 11, 0, 0, 0, 0, 564, NULL, 18),
(2297, 0, 0, 0, 'Sky Lane, Sea Tower', 4775, 11, 0, 0, 0, 0, 196, NULL, 6),
(2298, 0, 0, 0, 'Wood Avenue 6a', 1450, 11, 0, 0, 0, 0, 56, NULL, 2),
(2299, 0, 0, 0, 'Wood Avenue 9a', 1540, 11, 0, 0, 0, 0, 56, NULL, 2),
(2300, 0, 0, 0, 'Wood Avenue 10a', 1540, 11, 0, 0, 0, 0, 64, NULL, 2),
(2301, 0, 0, 0, 'Wood Avenue 11', 7205, 11, 0, 0, 0, 0, 253, NULL, 6),
(2302, 0, 0, 0, 'Wood Avenue 8', 5960, 11, 0, 0, 0, 0, 198, NULL, 3),
(2303, 0, 0, 0, 'Wood Avenue 7', 5960, 11, 0, 0, 0, 0, 191, NULL, 3),
(2304, 0, 0, 0, 'Wood Avenue 6b', 1450, 11, 0, 0, 0, 0, 56, NULL, 2),
(2305, 0, 0, 0, 'Wood Avenue 9b', 1495, 11, 0, 0, 0, 0, 56, NULL, 2),
(2306, 0, 0, 0, 'Wood Avenue 10b', 1595, 11, 0, 0, 0, 0, 64, NULL, 3),
(2307, 0, 0, 0, 'Wood Avenue 5', 1765, 11, 0, 0, 0, 0, 64, NULL, 2),
(2308, 0, 0, 0, 'Wood Avenue 4a', 1495, 11, 0, 0, 0, 0, 56, NULL, 2),
(2309, 0, 0, 0, 'Wood Avenue 4b', 1495, 11, 0, 0, 0, 0, 56, NULL, 2),
(2310, 0, 0, 0, 'Wood Avenue 4c', 1765, 11, 0, 0, 0, 0, 56, NULL, 2),
(2311, 0, 0, 0, 'Wood Avenue 4', 1765, 11, 0, 0, 0, 0, 64, NULL, 2),
(2312, 0, 0, 0, 'Wood Avenue 3', 1765, 11, 0, 0, 0, 0, 56, NULL, 2),
(2313, 0, 0, 0, 'Wood Avenue 2', 1765, 11, 0, 0, 0, 0, 49, NULL, 2),
(2314, 0, 0, 0, 'Wood Avenue 1', 1765, 11, 0, 0, 0, 0, 64, NULL, 2),
(2315, 0, 0, 0, 'Magic Academy, Guild', 12025, 11, 0, 0, 0, 0, 414, NULL, 14),
(2316, 0, 0, 0, 'Magic Academy, Flat 1', 1465, 11, 0, 0, 0, 0, 57, NULL, 3),
(2317, 0, 0, 0, 'Magic Academy, Flat 2', 1530, 11, 0, 0, 0, 0, 55, NULL, 2),
(2318, 0, 0, 0, 'Magic Academy, Flat 3', 1430, 11, 0, 0, 0, 0, 55, NULL, 1),
(2319, 0, 0, 0, 'Magic Academy, Flat 4', 1530, 11, 0, 0, 0, 0, 55, NULL, 2),
(2320, 0, 0, 0, 'Magic Academy, Flat 5', 1430, 11, 0, 0, 0, 0, 55, NULL, 1),
(2321, 0, 0, 0, 'Magic Academy, Shop', 1595, 11, 0, 0, 0, 0, 48, NULL, 1),
(2322, 0, 0, 0, 'Stonehome Village 1', 1780, 11, 0, 0, 0, 0, 74, NULL, 2),
(2323, 0, 0, 0, 'Stonehome Flats, Flat 05', 400, 11, 0, 0, 0, 0, 20, NULL, 1),
(2324, 0, 0, 0, 'Stonehome Flats, Flat 04', 400, 11, 0, 0, 0, 0, 25, NULL, 1),
(2325, 0, 0, 0, 'Stonehome Flats, Flat 06', 400, 11, 0, 0, 0, 0, 20, NULL, 1),
(2326, 0, 0, 0, 'Stonehome Flats, Flat 03', 400, 11, 0, 0, 0, 0, 20, NULL, 1),
(2327, 0, 0, 0, 'Stonehome Flats, Flat 01', 400, 11, 0, 0, 0, 0, 20, NULL, 1),
(2328, 0, 0, 0, 'Stonehome Flats, Flat 02', 740, 11, 0, 0, 0, 0, 30, NULL, 2),
(2329, 0, 0, 0, 'Stonehome Flats, Flat 11', 740, 11, 0, 0, 0, 0, 35, NULL, 2),
(2330, 0, 0, 0, 'Stonehome Flats, Flat 12', 740, 11, 0, 0, 0, 0, 35, NULL, 2),
(2331, 0, 0, 0, 'Stonehome Flats, Flat 13', 400, 11, 0, 0, 0, 0, 20, NULL, 1),
(2332, 0, 0, 0, 'Stonehome Flats, Flat 14', 400, 11, 0, 0, 0, 0, 20, NULL, 1),
(2333, 0, 0, 0, 'Stonehome Flats, Flat 16', 400, 11, 0, 0, 0, 0, 20, NULL, 1),
(2334, 0, 0, 0, 'Stonehome Flats, Flat 15', 400, 11, 0, 0, 0, 0, 20, NULL, 1),
(2335, 0, 0, 0, 'Stonehome Village 2', 640, 11, 0, 0, 0, 0, 35, NULL, 1),
(2336, 0, 0, 0, 'Stonehome Village 3', 680, 11, 0, 0, 0, 0, 36, NULL, 1),
(2337, 0, 0, 0, 'Stonehome Village 4', 940, 11, 0, 0, 0, 0, 42, NULL, 2),
(2338, 0, 0, 0, 'Stonehome Village 6', 1300, 11, 0, 0, 0, 0, 55, NULL, 2),
(2339, 0, 0, 0, 'Stonehome Village 5', 1140, 11, 0, 0, 0, 0, 56, NULL, 2),
(2340, 0, 0, 0, 'Stonehome Village 7', 1140, 11, 0, 0, 0, 0, 49, NULL, 2),
(2341, 0, 0, 0, 'Stonehome Village 8', 680, 11, 0, 0, 0, 0, 36, NULL, 1),
(2342, 0, 0, 0, 'Stonehome Village 9', 680, 11, 0, 0, 0, 0, 36, NULL, 1),
(2343, 0, 0, 0, 'Stonehome Clanhall', 8580, 11, 0, 0, 0, 0, 345, NULL, 9),
(2344, 0, 0, 0, 'Cormaya 1', 1270, 11, 0, 0, 0, 0, 49, NULL, 2),
(2345, 0, 0, 0, 'Cormaya 2', 3710, 11, 0, 0, 0, 0, 145, NULL, 3),
(2346, 0, 0, 0, 'Cormaya Flats, Flat 01', 450, 11, 0, 0, 0, 0, 20, NULL, 1),
(2347, 0, 0, 0, 'Cormaya Flats, Flat 02', 450, 11, 0, 0, 0, 0, 20, NULL, 1),
(2348, 0, 0, 0, 'Cormaya Flats, Flat 03', 820, 11, 0, 0, 0, 0, 30, NULL, 2),
(2349, 0, 0, 0, 'Cormaya Flats, Flat 06', 450, 11, 0, 0, 0, 0, 20, NULL, 1),
(2350, 0, 0, 0, 'Cormaya Flats, Flat 05', 450, 11, 0, 0, 0, 0, 20, NULL, 1),
(2351, 0, 0, 0, 'Cormaya Flats, Flat 04', 820, 11, 0, 0, 0, 0, 30, NULL, 2),
(2352, 0, 0, 0, 'Cormaya Flats, Flat 13', 820, 11, 0, 0, 0, 0, 30, NULL, 2),
(2353, 0, 0, 0, 'Cormaya Flats, Flat 14', 820, 11, 0, 0, 0, 0, 35, NULL, 2),
(2354, 0, 0, 0, 'Cormaya Flats, Flat 15', 450, 11, 0, 0, 0, 0, 20, NULL, 1),
(2355, 0, 0, 0, 'Cormaya Flats, Flat 16', 450, 11, 0, 0, 0, 0, 20, NULL, 1),
(2356, 0, 0, 0, 'Cormaya Flats, Flat 11', 450, 11, 0, 0, 0, 0, 20, NULL, 1),
(2357, 0, 0, 0, 'Cormaya Flats, Flat 12', 450, 11, 0, 0, 0, 0, 20, NULL, 1),
(2358, 0, 0, 0, 'Cormaya 3', 2035, 11, 0, 0, 0, 0, 72, NULL, 2),
(2359, 0, 0, 0, 'Castle of the White Dragon', 25110, 11, 0, 0, 0, 0, 761, NULL, 19),
(2360, 0, 0, 0, 'Cormaya 4', 1720, 11, 0, 0, 0, 0, 63, NULL, 2),
(2361, 0, 0, 0, 'Cormaya 5', 4250, 11, 0, 0, 0, 0, 167, NULL, 3),
(2362, 0, 0, 0, 'Cormaya 6', 2395, 11, 0, 0, 0, 0, 84, NULL, 2),
(2363, 0, 0, 0, 'Cormaya 7', 2395, 11, 0, 0, 0, 0, 84, NULL, 2),
(2364, 0, 0, 0, 'Cormaya 8', 2710, 11, 0, 0, 0, 0, 113, NULL, 2),
(2365, 0, 0, 0, 'Cormaya 9b', 2620, 11, 0, 0, 0, 0, 88, NULL, 2),
(2366, 0, 0, 0, 'Cormaya 9a', 1225, 11, 0, 0, 0, 0, 48, NULL, 2),
(2367, 0, 0, 0, 'Cormaya 9c', 1225, 11, 0, 0, 0, 0, 48, NULL, 2),
(2368, 0, 0, 0, 'Cormaya 9d', 2620, 11, 0, 0, 0, 0, 88, NULL, 2),
(2369, 0, 0, 0, 'Cormaya 10', 3800, 11, 0, 0, 0, 0, 140, NULL, 3),
(2370, 0, 0, 0, 'Cormaya 11', 2035, 11, 0, 0, 0, 0, 72, NULL, 2),
(2371, 0, 0, 0, 'Demon Tower', 3340, 2, 0, 0, 0, 0, 127, NULL, 2),
(2372, 0, 0, 0, 'Nautic Observer', 6540, 4, 0, 0, 0, 0, 300, NULL, 4),
(2373, 0, 0, 0, 'Riverspring', 19450, 3, 0, 0, 0, 0, 565, NULL, 18),
(2374, 0, 0, 0, 'House of Recreation', 22540, 4, 0, 0, 0, 0, 702, NULL, 16),
(2375, 0, 0, 0, 'Valorous Venore', 14435, 1, 0, 0, 0, 0, 496, NULL, 9),
(2376, 0, 0, 0, 'Ab\'Dendriel Clanhall', 14850, 5, 0, 0, 0, 0, 405, NULL, 10),
(2377, 0, 0, 0, 'Castle of the Winds', 23885, 5, 0, 0, 0, 0, 842, NULL, 18),
(2378, 0, 0, 0, 'The Hideout', 20800, 5, 0, 0, 0, 0, 597, NULL, 20),
(2379, 0, 0, 0, 'Shadow Towers', 21800, 5, 0, 0, 0, 0, 750, NULL, 18),
(2380, 0, 0, 0, 'Hill Hideout', 13950, 3, 0, 0, 0, 0, 346, NULL, 15),
(2381, 0, 0, 0, 'Meriana Beach', 8230, 7, 0, 0, 0, 0, 184, NULL, 3),
(2382, 0, 0, 0, 'Darashia 8, Flat 01', 2485, 10, 0, 0, 0, 0, 80, NULL, 2),
(2383, 0, 0, 0, 'Darashia 8, Flat 02', 3385, 10, 0, 0, 0, 0, 114, NULL, 2),
(2384, 0, 0, 0, 'Darashia 8, Flat 03', 4700, 10, 0, 0, 0, 0, 171, NULL, 3),
(2385, 0, 0, 0, 'Darashia 8, Flat 04', 2845, 10, 0, 0, 0, 0, 90, NULL, 2),
(2386, 0, 0, 0, 'Darashia 8, Flat 05', 2665, 10, 0, 0, 0, 0, 85, NULL, 2),
(2387, 0, 0, 0, 'Darashia, Eastern Guildhall', 12660, 10, 0, 0, 0, 0, 444, NULL, 16),
(2388, 0, 0, 0, 'Theater Avenue 5a', 450, 4, 0, 0, 0, 0, 20, NULL, 1),
(2389, 0, 0, 0, 'Theater Avenue 5b', 450, 4, 0, 0, 0, 0, 19, NULL, 1),
(2390, 0, 0, 0, 'Theater Avenue 5c', 450, 4, 0, 0, 0, 0, 16, NULL, 1),
(2391, 0, 0, 0, 'Theater Avenue 5d', 450, 4, 0, 0, 0, 0, 16, NULL, 1),
(2392, 0, 0, 0, 'Outlaw Camp 1', 1660, 3, 0, 0, 0, 0, 52, NULL, 2),
(2393, 0, 0, 0, 'Outlaw Camp 2', 280, 3, 0, 0, 0, 0, 12, NULL, 1),
(2394, 0, 0, 0, 'Outlaw Camp 3', 740, 3, 0, 0, 0, 0, 27, NULL, 2),
(2395, 0, 0, 0, 'Outlaw Camp 4', 200, 3, 0, 0, 0, 0, 9, NULL, 1),
(2396, 0, 0, 0, 'Outlaw Camp 5', 200, 3, 0, 0, 0, 0, 9, NULL, 1),
(2397, 0, 0, 0, 'Outlaw Camp 6', 200, 3, 0, 0, 0, 0, 9, NULL, 1),
(2398, 0, 0, 0, 'Outlaw Camp 7', 780, 3, 0, 0, 0, 0, 27, NULL, 2),
(2399, 0, 0, 0, 'Outlaw Camp 8', 280, 3, 0, 0, 0, 0, 12, NULL, 1),
(2400, 0, 0, 0, 'Outlaw Camp 9', 200, 3, 0, 0, 0, 0, 9, NULL, 1),
(2401, 0, 0, 0, 'Outlaw Camp 10', 200, 3, 0, 0, 0, 0, 9, NULL, 1),
(2402, 0, 0, 0, 'Outlaw Camp 11', 200, 3, 0, 0, 0, 0, 9, NULL, 1),
(2404, 0, 0, 0, 'Outlaw Camp 12 (Shop)', 280, 3, 0, 0, 0, 0, 7, NULL, 0),
(2405, 0, 0, 0, 'Outlaw Camp 13 (Shop)', 280, 3, 0, 0, 0, 0, 7, NULL, 0),
(2406, 0, 0, 0, 'Outlaw Camp 14 (Shop)', 640, 3, 0, 0, 0, 0, 16, NULL, 0),
(2407, 0, 0, 0, 'Open-Air Theatre', 2700, 2, 0, 0, 0, 0, 60, NULL, 1),
(2408, 0, 0, 0, 'The Lair', 7625, 1, 0, 0, 0, 0, 165, NULL, 3),
(2409, 0, 0, 0, 'Upper Barracks 2', 210, 3, 0, 0, 0, 0, 13, NULL, 1),
(2410, 0, 0, 0, 'Upper Barracks 3', 210, 3, 0, 0, 0, 0, 13, NULL, 1),
(2411, 0, 0, 0, 'Upper Barracks 4', 210, 3, 0, 0, 0, 0, 14, NULL, 1),
(2412, 0, 0, 0, 'Upper Barracks 5', 210, 3, 0, 0, 0, 0, 12, NULL, 1),
(2413, 0, 0, 0, 'Upper Barracks 6', 210, 3, 0, 0, 0, 0, 12, NULL, 1),
(2414, 0, 0, 0, 'Upper Barracks 7', 210, 3, 0, 0, 0, 0, 12, NULL, 1),
(2415, 0, 0, 0, 'Upper Barracks 8', 210, 3, 0, 0, 0, 0, 13, NULL, 1),
(2416, 0, 0, 0, 'Upper Barracks 9', 210, 3, 0, 0, 0, 0, 13, NULL, 1),
(2417, 0, 0, 0, 'Upper Barracks 10', 210, 3, 0, 0, 0, 0, 13, NULL, 1),
(2418, 0, 0, 0, 'Upper Barracks 11', 210, 3, 0, 0, 0, 0, 14, NULL, 1),
(2419, 0, 0, 0, 'Upper Barracks 12', 210, 3, 0, 0, 0, 0, 12, NULL, 1),
(2420, 0, 0, 0, 'Low Waters Observatory', 17165, 9, 0, 0, 0, 0, 721, NULL, 5),
(2421, 0, 0, 0, 'Eastern House of Tranquility', 11120, 14, 0, 0, 0, 0, 356, NULL, 5),
(2422, 0, 0, 0, 'Mammoth House', 9300, 12, 0, 0, 0, 0, 218, NULL, 6),
(2427, 0, 0, 0, 'Lower Barracks 1', 300, 3, 0, 0, 0, 0, 17, NULL, 1),
(2428, 0, 0, 0, 'Lower Barracks 2', 300, 3, 0, 0, 0, 0, 16, NULL, 1),
(2429, 0, 0, 0, 'Lower Barracks 3', 300, 3, 0, 0, 0, 0, 17, NULL, 1),
(2430, 0, 0, 0, 'Lower Barracks 4', 300, 3, 0, 0, 0, 0, 16, NULL, 1),
(2431, 0, 0, 0, 'Lower Barracks 5', 300, 3, 0, 0, 0, 0, 17, NULL, 1),
(2432, 0, 0, 0, 'Lower Barracks 6', 300, 3, 0, 0, 0, 0, 15, NULL, 1),
(2433, 0, 0, 0, 'Lower Barracks 7', 300, 3, 0, 0, 0, 0, 17, NULL, 1),
(2434, 0, 0, 0, 'Lower Barracks 8', 300, 3, 0, 0, 0, 0, 16, NULL, 1),
(2435, 0, 0, 0, 'Lower Barracks 9', 300, 3, 0, 0, 0, 0, 17, NULL, 1),
(2436, 0, 0, 0, 'Lower Barracks 10', 300, 3, 0, 0, 0, 0, 16, NULL, 1),
(2437, 0, 0, 0, 'Lower Barracks 11', 300, 3, 0, 0, 0, 0, 17, NULL, 1),
(2438, 0, 0, 0, 'Lower Barracks 12', 300, 3, 0, 0, 0, 0, 16, NULL, 1),
(2439, 0, 0, 0, 'Lower Barracks 13', 300, 3, 0, 0, 0, 0, 17, NULL, 1),
(2440, 0, 0, 0, 'Lower Barracks 14', 300, 3, 0, 0, 0, 0, 16, NULL, 1),
(2441, 0, 0, 0, 'Lower Barracks 15', 300, 3, 0, 0, 0, 0, 17, NULL, 1),
(2442, 0, 0, 0, 'Lower Barracks 16', 300, 3, 0, 0, 0, 0, 16, NULL, 1),
(2443, 0, 0, 0, 'Lower Barracks 17', 300, 3, 0, 0, 0, 0, 17, NULL, 1),
(2444, 0, 0, 0, 'Lower Barracks 18', 300, 3, 0, 0, 0, 0, 16, NULL, 1),
(2445, 0, 0, 0, 'Lower Barracks 19', 300, 3, 0, 0, 0, 0, 17, NULL, 1),
(2446, 0, 0, 0, 'Lower Barracks 20', 300, 3, 0, 0, 0, 0, 16, NULL, 1),
(2447, 0, 0, 0, 'Lower Barracks 21', 300, 3, 0, 0, 0, 0, 17, NULL, 1),
(2448, 0, 0, 0, 'Lower Barracks 22', 300, 3, 0, 0, 0, 0, 16, NULL, 1),
(2449, 0, 0, 0, 'Lower Barracks 23', 300, 3, 0, 0, 0, 0, 17, NULL, 1),
(2450, 0, 0, 0, 'Lower Barracks 24', 300, 3, 0, 0, 0, 0, 16, NULL, 1),
(2451, 0, 0, 0, 'The Farms 4', 1530, 3, 0, 0, 0, 0, 36, NULL, 2),
(2452, 0, 0, 0, 'Tunnel Gardens 1', 2000, 3, 0, 0, 0, 0, 40, NULL, 3),
(2455, 0, 0, 0, 'Tunnel Gardens 2', 2000, 3, 0, 0, 0, 0, 39, NULL, 3),
(2456, 0, 0, 0, 'The Yeah Beach Project', 6525, 7, 0, 0, 0, 0, 183, NULL, 3),
(2460, 0, 0, 0, 'Hare\'s Den', 7500, 3, 0, 0, 0, 0, 233, NULL, 4),
(2461, 0, 0, 0, 'Lost Cavern', 14730, 3, 0, 0, 0, 0, 621, NULL, 7),
(2462, 0, 0, 0, 'Caveman Shelter', 3780, 14, 0, 0, 0, 0, 92, NULL, 4),
(2463, 0, 0, 0, 'Old Sanctuary of God King Qjell', 21940, 28, 0, 0, 0, 0, 854, NULL, 6),
(2464, 0, 0, 0, 'Wallside Lane 1', 7590, 33, 0, 0, 0, 0, 295, NULL, 4),
(2465, 0, 0, 0, 'Wallside Residence', 6680, 33, 0, 0, 0, 0, 223, NULL, 4),
(2466, 0, 0, 0, 'Wallside Lane 2', 8445, 33, 0, 0, 0, 0, 294, NULL, 4),
(2467, 0, 0, 0, 'Antimony Lane 3', 3665, 33, 0, 0, 0, 0, 126, NULL, 3),
(2468, 0, 0, 0, 'Antimony Lane 2', 4745, 33, 0, 0, 0, 0, 159, NULL, 3),
(2469, 0, 0, 0, 'Vanward Flats B', 7410, 33, 0, 0, 0, 0, 245, NULL, 4),
(2470, 0, 0, 0, 'Vanward Flats A', 7410, 33, 0, 0, 0, 0, 222, NULL, 4),
(2471, 0, 0, 0, 'Bronze Brothers Bastion', 35205, 33, 0, 0, 0, 0, 1181, NULL, 15),
(2472, 0, 0, 0, 'Antimony Lane 1', 7105, 33, 0, 0, 0, 0, 242, NULL, 5),
(2473, 0, 0, 0, 'Rathleton Hills Estate', 20685, 33, 0, 0, 0, 0, 646, NULL, 13),
(2474, 0, 0, 0, 'Rathleton Hills Residence', 7085, 33, 0, 0, 0, 0, 228, NULL, 3),
(2475, 0, 0, 0, 'Rathleton Plaza 1', 2890, 33, 0, 0, 0, 0, 95, NULL, 2),
(2476, 0, 0, 0, 'Rathleton Plaza 2', 2620, 33, 0, 0, 0, 0, 99, NULL, 2),
(2478, 0, 0, 0, 'Antimony Lane 4', 5150, 33, 0, 0, 0, 0, 176, NULL, 3),
(2480, 0, 0, 0, 'Old Heritage Estate', 12075, 33, 0, 0, 0, 0, 402, NULL, 7),
(2481, 0, 0, 0, 'Cistern Ave', 3745, 33, 0, 0, 0, 0, 173, NULL, 2),
(2482, 0, 0, 0, 'Rathleton Plaza 4', 5005, 33, 0, 0, 0, 0, 193, NULL, 2),
(2483, 0, 0, 0, 'Rathleton Plaza 3', 5735, 33, 0, 0, 0, 0, 193, NULL, 3),
(2488, 0, 0, 0, 'Thrarhor V e (Shop)', 3000, 9, 0, 0, 0, 0, 36, NULL, 1),
(2491, 0, 0, 0, 'Isle of Solitude House', 3000, 31, 0, 0, 0, 0, 529, NULL, 14),
(2492, 0, 0, 0, 'Marketplace 1', 400000, 63, 0, 0, 0, 0, 147, NULL, 1),
(2493, 0, 0, 0, 'Marketplace 2', 400000, 63, 0, 0, 0, 0, 166, NULL, 2),
(2495, 0, 0, 0, 'Quay 1', 200000, 63, 0, 0, 0, 0, 191, NULL, 4),
(2496, 0, 0, 0, 'Quay 2', 200000, 63, 0, 0, 0, 0, 148, NULL, 2),
(2497, 0, 0, 0, 'Wave Tower', 400000, 63, 0, 0, 0, 0, 358, NULL, 4),
(2498, 0, 0, 0, 'Halls of Sun and Sea', 1000000, 63, 0, 0, 0, 0, 611, NULL, 11),
(2500, 0, 0, 0, 'Holy Castle', 0, 65, 0, 0, 0, 0, 3065, NULL, 20);

-- --------------------------------------------------------

--
-- Estrutura da tabela `house_lists`
--

CREATE TABLE `house_lists` (
  `house_id` int(11) NOT NULL,
  `listid` int(11) NOT NULL,
  `list` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Estrutura da tabela `ip_bans`
--

CREATE TABLE `ip_bans` (
  `ip` int(10) UNSIGNED NOT NULL,
  `reason` varchar(255) NOT NULL,
  `banned_at` bigint(20) NOT NULL,
  `expires_at` bigint(20) NOT NULL,
  `banned_by` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Estrutura da tabela `live_casts`
--

CREATE TABLE `live_casts` (
  `player_id` int(11) NOT NULL,
  `cast_name` varchar(255) NOT NULL,
  `password` tinyint(1) NOT NULL DEFAULT 0,
  `description` varchar(255) DEFAULT NULL,
  `spectators` smallint(5) DEFAULT 0,
  `version` int(10) DEFAULT 1220
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Estrutura da tabela `market_history`
--

CREATE TABLE `market_history` (
  `id` int(10) UNSIGNED NOT NULL,
  `player_id` int(11) NOT NULL,
  `sale` tinyint(1) NOT NULL DEFAULT 0,
  `itemtype` int(10) UNSIGNED NOT NULL,
  `amount` smallint(5) UNSIGNED NOT NULL,
  `price` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `expires_at` bigint(20) UNSIGNED NOT NULL,
  `inserted` bigint(20) UNSIGNED NOT NULL,
  `state` tinyint(1) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Estrutura da tabela `market_offers`
--

CREATE TABLE `market_offers` (
  `id` int(10) UNSIGNED NOT NULL,
  `player_id` int(11) NOT NULL,
  `sale` tinyint(1) NOT NULL DEFAULT 0,
  `itemtype` int(10) UNSIGNED NOT NULL,
  `amount` smallint(5) UNSIGNED NOT NULL,
  `created` bigint(20) UNSIGNED NOT NULL,
  `anonymous` tinyint(1) NOT NULL DEFAULT 0,
  `price` int(10) UNSIGNED NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Estrutura da tabela `newsticker`
--

CREATE TABLE `newsticker` (
  `id` int(10) UNSIGNED NOT NULL,
  `date` int(11) NOT NULL,
  `text` mediumtext NOT NULL,
  `icon` varchar(50) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Estrutura da tabela `pagseguro`
--

CREATE TABLE `pagseguro` (
  `date` datetime NOT NULL,
  `code` varchar(50) NOT NULL,
  `reference` varchar(200) NOT NULL,
  `type` int(11) NOT NULL,
  `status` int(11) NOT NULL,
  `lastEventDate` datetime NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Estrutura da tabela `pagseguro_transactions`
--

CREATE TABLE `pagseguro_transactions` (
  `transaction_code` varchar(36) NOT NULL,
  `name` varchar(200) DEFAULT NULL,
  `payment_method` varchar(50) NOT NULL,
  `status` varchar(50) NOT NULL,
  `item_count` int(11) NOT NULL,
  `data` datetime NOT NULL,
  `payment_amount` float DEFAULT 0
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Estrutura da tabela `paypal_transactions`
--

CREATE TABLE `paypal_transactions` (
  `id` int(11) NOT NULL,
  `payment_status` varchar(70) NOT NULL DEFAULT '',
  `date` datetime NOT NULL,
  `payer_email` varchar(255) NOT NULL DEFAULT '',
  `payer_id` varchar(255) NOT NULL DEFAULT '',
  `item_number1` varchar(255) NOT NULL DEFAULT '',
  `mc_gross` float NOT NULL,
  `mc_currency` varchar(5) NOT NULL DEFAULT '',
  `txn_id` varchar(255) NOT NULL DEFAULT ''
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

-- --------------------------------------------------------

--
-- Estrutura da tabela `players`
--

CREATE TABLE `players` (
  `id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `group_id` int(11) NOT NULL DEFAULT 1,
  `account_id` int(11) NOT NULL DEFAULT 0,
  `level` int(11) NOT NULL DEFAULT 1,
  `vocation` int(11) NOT NULL DEFAULT 0,
  `health` int(11) NOT NULL DEFAULT 150,
  `healthmax` int(11) NOT NULL DEFAULT 150,
  `experience` bigint(20) NOT NULL DEFAULT 0,
  `exptoday` int(11) DEFAULT NULL,
  `lookbody` int(11) NOT NULL DEFAULT 0,
  `lookfeet` int(11) NOT NULL DEFAULT 0,
  `lookhead` int(11) NOT NULL DEFAULT 0,
  `looklegs` int(11) NOT NULL DEFAULT 0,
  `looktype` int(11) NOT NULL DEFAULT 136,
  `lookaddons` int(11) NOT NULL DEFAULT 0,
  `maglevel` int(11) NOT NULL DEFAULT 0,
  `mana` int(11) NOT NULL DEFAULT 0,
  `manamax` int(11) NOT NULL DEFAULT 0,
  `manaspent` bigint(20) UNSIGNED NOT NULL DEFAULT 0,
  `soul` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `town_id` int(11) NOT NULL DEFAULT 0,
  `posx` int(11) NOT NULL DEFAULT 0,
  `posy` int(11) NOT NULL DEFAULT 0,
  `posz` int(11) NOT NULL DEFAULT 0,
  `conditions` blob NOT NULL,
  `cap` int(11) NOT NULL DEFAULT 0,
  `sex` int(11) NOT NULL DEFAULT 0,
  `lastlogin` bigint(20) UNSIGNED NOT NULL DEFAULT 0,
  `lastip` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `save` tinyint(1) NOT NULL DEFAULT 1,
  `skull` tinyint(1) NOT NULL DEFAULT 0,
  `skulltime` bigint(20) NOT NULL DEFAULT 0,
  `lastlogout` bigint(20) UNSIGNED NOT NULL DEFAULT 0,
  `blessings` tinyint(2) NOT NULL DEFAULT 0,
  `blessings1` tinyint(4) NOT NULL DEFAULT 0,
  `blessings2` tinyint(4) NOT NULL DEFAULT 0,
  `blessings3` tinyint(4) NOT NULL DEFAULT 0,
  `blessings4` tinyint(4) NOT NULL DEFAULT 0,
  `blessings5` tinyint(4) NOT NULL DEFAULT 0,
  `blessings6` tinyint(4) NOT NULL DEFAULT 0,
  `blessings7` tinyint(4) NOT NULL DEFAULT 0,
  `blessings8` tinyint(4) NOT NULL DEFAULT 0,
  `onlinetime` bigint(20) NOT NULL DEFAULT 0,
  `deletion` bigint(15) NOT NULL DEFAULT 0,
  `balance` bigint(20) UNSIGNED NOT NULL DEFAULT 0,
  `bonusrerollcount` bigint(20) DEFAULT 0,
  `quick_loot_fallback` tinyint(1) DEFAULT 0,
  `offlinetraining_time` smallint(5) UNSIGNED NOT NULL DEFAULT 43200,
  `offlinetraining_skill` int(11) NOT NULL DEFAULT -1,
  `stamina` smallint(5) UNSIGNED NOT NULL DEFAULT 2520,
  `skill_fist` int(10) UNSIGNED NOT NULL DEFAULT 10,
  `skill_fist_tries` bigint(20) UNSIGNED NOT NULL DEFAULT 0,
  `skill_club` int(10) UNSIGNED NOT NULL DEFAULT 10,
  `skill_club_tries` bigint(20) UNSIGNED NOT NULL DEFAULT 0,
  `skill_sword` int(10) UNSIGNED NOT NULL DEFAULT 10,
  `skill_sword_tries` bigint(20) UNSIGNED NOT NULL DEFAULT 0,
  `skill_axe` int(10) UNSIGNED NOT NULL DEFAULT 10,
  `skill_axe_tries` bigint(20) UNSIGNED NOT NULL DEFAULT 0,
  `skill_dist` int(10) UNSIGNED NOT NULL DEFAULT 10,
  `skill_dist_tries` bigint(20) UNSIGNED NOT NULL DEFAULT 0,
  `skill_shielding` int(10) UNSIGNED NOT NULL DEFAULT 10,
  `skill_shielding_tries` bigint(20) UNSIGNED NOT NULL DEFAULT 0,
  `skill_fishing` int(10) UNSIGNED NOT NULL DEFAULT 10,
  `skill_fishing_tries` bigint(20) UNSIGNED NOT NULL DEFAULT 0,
  `deleted` tinyint(1) NOT NULL DEFAULT 0,
  `description` varchar(255) NOT NULL DEFAULT '',
  `comment` text NOT NULL,
  `create_ip` bigint(20) NOT NULL DEFAULT 0,
  `create_date` bigint(20) NOT NULL DEFAULT 0,
  `hide_char` int(11) NOT NULL DEFAULT 0,
  `skill_critical_hit_chance` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `skill_critical_hit_chance_tries` bigint(20) UNSIGNED NOT NULL DEFAULT 0,
  `skill_critical_hit_damage` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `skill_critical_hit_damage_tries` bigint(20) UNSIGNED NOT NULL DEFAULT 0,
  `skill_life_leech_chance` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `skill_life_leech_chance_tries` bigint(20) UNSIGNED NOT NULL DEFAULT 0,
  `skill_life_leech_amount` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `skill_life_leech_amount_tries` bigint(20) UNSIGNED NOT NULL DEFAULT 0,
  `skill_mana_leech_chance` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `skill_mana_leech_chance_tries` bigint(20) UNSIGNED NOT NULL DEFAULT 0,
  `skill_mana_leech_amount` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `skill_mana_leech_amount_tries` bigint(20) UNSIGNED NOT NULL DEFAULT 0,
  `skill_criticalhit_chance` bigint(20) UNSIGNED NOT NULL DEFAULT 0,
  `skill_criticalhit_damage` bigint(20) UNSIGNED NOT NULL DEFAULT 0,
  `skill_lifeleech_chance` bigint(20) UNSIGNED NOT NULL DEFAULT 0,
  `skill_lifeleech_amount` bigint(20) UNSIGNED NOT NULL DEFAULT 0,
  `skill_manaleech_chance` bigint(20) UNSIGNED NOT NULL DEFAULT 0,
  `skill_manaleech_amount` bigint(20) UNSIGNED NOT NULL DEFAULT 0,
  `prey_stamina_1` int(11) DEFAULT NULL,
  `prey_stamina_2` int(11) DEFAULT NULL,
  `prey_stamina_3` int(11) DEFAULT NULL,
  `prey_column` smallint(6) NOT NULL DEFAULT 1,
  `xpboost_stamina` int(11) DEFAULT NULL,
  `xpboost_value` int(10) DEFAULT NULL,
  `marriage_status` bigint(20) UNSIGNED NOT NULL DEFAULT 0,
  `hide_skills` int(11) DEFAULT NULL,
  `hide_set` int(11) DEFAULT NULL,
  `former` varchar(255) NOT NULL DEFAULT '-',
  `signature` varchar(255) NOT NULL DEFAULT '',
  `marriage_spouse` int(11) NOT NULL DEFAULT -1,
  `loyalty_ranking` tinyint(1) NOT NULL DEFAULT 0,
  `bonus_rerolls` bigint(21) NOT NULL DEFAULT 0,
  `critical` int(20) DEFAULT 0,
  `sbw_points` int(11) NOT NULL DEFAULT 0,
  `instantrewardtokens` int(11) UNSIGNED NOT NULL DEFAULT 0,
  `charmpoints` int(11) DEFAULT 0,
  `direction` tinyint(1) DEFAULT 0,
  `lookmount` int(11) DEFAULT 0,
  `version` int(11) DEFAULT 1000,
  `lootaction` tinyint(2) DEFAULT 0,
  `spells` blob DEFAULT NULL,
  `storages` mediumblob DEFAULT NULL,
  `items` longblob DEFAULT NULL,
  `depotitems` longblob DEFAULT NULL,
  `inboxitems` longblob DEFAULT NULL,
  `rewards` longblob DEFAULT NULL,
  `varcap` int(11) NOT NULL DEFAULT 0,
  `charmExpansion` tinyint(2) DEFAULT 0,
  `bestiarykills` longblob DEFAULT NULL,
  `charms` longblob DEFAULT NULL,
  `bestiaryTracker` longblob DEFAULT NULL,
  `autoloot` blob DEFAULT NULL,
  `lastday` bigint(22) DEFAULT 0,
  `bonus_reroll` int(11) NOT NULL DEFAULT 0,
  `lookmountbody` tinyint(3) UNSIGNED NOT NULL DEFAULT 0,
  `lookmountfeet` tinyint(3) UNSIGNED NOT NULL DEFAULT 0,
  `lookmounthead` tinyint(3) UNSIGNED NOT NULL DEFAULT 0,
  `lookmountlegs` tinyint(3) UNSIGNED NOT NULL DEFAULT 0,
  `lookfamiliarstype` int(11) UNSIGNED NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Extraindo dados da tabela `players`
--

INSERT INTO `players` (`id`, `name`, `group_id`, `account_id`, `level`, `vocation`, `health`, `healthmax`, `experience`, `exptoday`, `lookbody`, `lookfeet`, `lookhead`, `looklegs`, `looktype`, `lookaddons`, `maglevel`, `mana`, `manamax`, `manaspent`, `soul`, `town_id`, `posx`, `posy`, `posz`, `conditions`, `cap`, `sex`, `lastlogin`, `lastip`, `save`, `skull`, `skulltime`, `lastlogout`, `blessings`, `blessings1`, `blessings2`, `blessings3`, `blessings4`, `blessings5`, `blessings6`, `blessings7`, `blessings8`, `onlinetime`, `deletion`, `balance`, `bonusrerollcount`, `quick_loot_fallback`, `offlinetraining_time`, `offlinetraining_skill`, `stamina`, `skill_fist`, `skill_fist_tries`, `skill_club`, `skill_club_tries`, `skill_sword`, `skill_sword_tries`, `skill_axe`, `skill_axe_tries`, `skill_dist`, `skill_dist_tries`, `skill_shielding`, `skill_shielding_tries`, `skill_fishing`, `skill_fishing_tries`, `deleted`, `description`, `comment`, `create_ip`, `create_date`, `hide_char`, `skill_critical_hit_chance`, `skill_critical_hit_chance_tries`, `skill_critical_hit_damage`, `skill_critical_hit_damage_tries`, `skill_life_leech_chance`, `skill_life_leech_chance_tries`, `skill_life_leech_amount`, `skill_life_leech_amount_tries`, `skill_mana_leech_chance`, `skill_mana_leech_chance_tries`, `skill_mana_leech_amount`, `skill_mana_leech_amount_tries`, `skill_criticalhit_chance`, `skill_criticalhit_damage`, `skill_lifeleech_chance`, `skill_lifeleech_amount`, `skill_manaleech_chance`, `skill_manaleech_amount`, `prey_stamina_1`, `prey_stamina_2`, `prey_stamina_3`, `prey_column`, `xpboost_stamina`, `xpboost_value`, `marriage_status`, `hide_skills`, `hide_set`, `former`, `signature`, `marriage_spouse`, `loyalty_ranking`, `bonus_rerolls`, `critical`, `sbw_points`, `instantrewardtokens`, `charmpoints`, `direction`, `lookmount`, `version`, `lootaction`, `spells`, `storages`, `items`, `depotitems`, `inboxitems`, `rewards`, `varcap`, `charmExpansion`, `bestiarykills`, `charms`, `bestiaryTracker`, `autoloot`, `lastday`, `bonus_reroll`, `lookmountbody`, `lookmountfeet`, `lookmounthead`, `lookmountlegs`, `lookfamiliarstype`) VALUES
(1, 'Rook Sample', 1, 1, 1, 0, 150, 150, 0, NULL, 106, 76, 78, 58, 136, 0, 0, 5, 5, 0, 0, 6, 32097, 32205, 7, '', 400, 0, 1594061826, 16777343, 1, 0, 0, 1594062801, 0, 0, 1, 1, 1, 1, 1, 0, 0, 2936, 0, 0, 0, 0, 43200, -1, 2520, 10, 0, 10, 0, 10, 0, 10, 0, 10, 0, 10, 0, 10, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, NULL, 1, 0, 0, 0, NULL, NULL, '-', '', -1, 0, 0, 0, 0, 0, 0, 0, 0, 1230, 0, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0, 0, 0, 0, 0, 0, 0),
(2, 'Sorcerer Sample', 1, 1, 8, 1, 185, 185, 4200, NULL, 44, 98, 15, 76, 128, 0, 0, 90, 90, 0, 100, 1, 0, 0, 0, '', 470, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 43200, -1, 2520, 10, 0, 10, 0, 10, 0, 10, 0, 10, 0, 10, 0, 10, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, NULL, 1, NULL, NULL, 0, NULL, NULL, '-', '', -1, 0, 0, 0, 0, 0, 0, 0, 0, 1000, 0, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0, NULL, NULL, NULL, NULL, 0, 0, 0, 0, 0, 0, 0),
(3, 'Druid Sample', 1, 1, 8, 2, 185, 185, 4200, NULL, 44, 98, 15, 76, 128, 0, 0, 90, 90, 0, 100, 1, 0, 0, 0, '', 470, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 43200, -1, 2520, 10, 0, 10, 0, 10, 0, 10, 0, 10, 0, 10, 0, 10, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, NULL, 1, NULL, NULL, 0, NULL, NULL, '-', '', -1, 0, 0, 0, 0, 0, 0, 0, 0, 1000, 0, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0, NULL, NULL, NULL, NULL, 0, 0, 0, 0, 0, 0, 0),
(4, 'Paladin Sample', 1, 1, 8, 3, 185, 185, 4200, NULL, 44, 98, 15, 76, 128, 0, 0, 90, 90, 0, 100, 1, 0, 0, 0, '', 470, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 43200, -1, 2520, 10, 0, 10, 0, 10, 0, 10, 0, 10, 0, 10, 0, 10, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, NULL, 1, NULL, NULL, 0, NULL, NULL, '-', '', -1, 0, 0, 0, 0, 0, 0, 0, 0, 1000, 0, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0, NULL, NULL, NULL, NULL, 0, 0, 0, 0, 0, 0, 0),
(5, 'Knight Sample', 1, 1, 202, 4, 3095, 3095, 135017843, NULL, 106, 76, 78, 58, 136, 0, 1, 1060, 1060, 3196, 100, 1, 95, 117, 7, '', 5320, 0, 1751843320, 16777343, 1, 0, 0, 1751843373, 0, 0, 0, 0, 0, 0, 0, 0, 0, 312, 0, 0, 0, 0, 43200, -1, 2518, 10, 0, 10, 0, 10, 0, 10, 0, 10, 0, 10, 0, 10, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, NULL, 1, 0, 0, 0, NULL, NULL, '-', '', -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0, 0x010000000000000015000300000000, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0, 0, 0, 0, 0, 0, 0),
(6, 'God', 6, 1, 1, 0, 185, 185, 0, NULL, 106, 76, 78, 58, 136, 0, 0, 90, 90, 0, 100, 1, 97, 122, 7, '', 470, 0, 1751843220, 16777343, 1, 0, 0, 1751843238, 0, 0, 0, 0, 0, 0, 0, 0, 0, 10665, 0, 0, 0, 0, 43200, -1, 2520, 10, 0, 10, 0, 10, 0, 10, 0, 10, 0, 10, 0, 10, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, NULL, 1, 0, 0, 0, NULL, NULL, '-', '', -1, 0, 0, 0, 0, 0, 0, 1, 0, 1100, 0, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0, 0, 0, 0, 0, 0, 0);

-- --------------------------------------------------------

--
-- Estrutura da tabela `players_online`
--

CREATE TABLE `players_online` (
  `player_id` int(11) NOT NULL
) ENGINE=MEMORY DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Estrutura da tabela `player_binary_items`
--

CREATE TABLE `player_binary_items` (
  `player_id` int(11) NOT NULL,
  `type` int(11) NOT NULL,
  `items` longblob NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

-- --------------------------------------------------------

--
-- Estrutura da tabela `player_deaths`
--

CREATE TABLE `player_deaths` (
  `player_id` int(11) NOT NULL,
  `time` bigint(20) UNSIGNED NOT NULL DEFAULT 0,
  `level` int(11) NOT NULL DEFAULT 1,
  `killed_by` varchar(255) NOT NULL,
  `is_player` tinyint(1) NOT NULL DEFAULT 1,
  `mostdamage_by` varchar(100) NOT NULL,
  `mostdamage_is_player` tinyint(1) NOT NULL DEFAULT 0,
  `unjustified` tinyint(1) NOT NULL DEFAULT 0,
  `mostdamage_unjustified` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Extraindo dados da tabela `player_deaths`
--

INSERT INTO `player_deaths` (`player_id`, `time`, `level`, `killed_by`, `is_player`, `mostdamage_by`, `mostdamage_is_player`, `unjustified`, `mostdamage_unjustified`) VALUES
(5, 1751843025, 208, 'Demon', 0, 'Demon', 0, 0, 0),
(5, 1751843287, 205, 'Dragon Lord', 0, 'Dragon Lord', 0, 0, 0);

-- --------------------------------------------------------

--
-- Estrutura da tabela `player_depotitems`
--

CREATE TABLE `player_depotitems` (
  `player_id` int(11) NOT NULL,
  `sid` int(11) NOT NULL COMMENT 'any given range eg 0-100 will be reserved for depot lockers and all > 100 will be then normal items inside depots',
  `pid` int(11) NOT NULL DEFAULT 0,
  `itemtype` int(11) NOT NULL DEFAULT 0,
  `count` int(11) NOT NULL DEFAULT 0,
  `attributes` blob NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Estrutura da tabela `player_former_names`
--

CREATE TABLE `player_former_names` (
  `id` int(11) NOT NULL,
  `player_id` int(11) NOT NULL,
  `former_name` varchar(35) NOT NULL,
  `date` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Estrutura da tabela `player_hirelings`
--

CREATE TABLE `player_hirelings` (
  `id` int(11) NOT NULL,
  `player_id` int(11) NOT NULL,
  `name` varchar(255) DEFAULT NULL,
  `active` tinyint(3) UNSIGNED NOT NULL DEFAULT 0,
  `sex` tinyint(3) UNSIGNED NOT NULL DEFAULT 0,
  `posx` int(11) NOT NULL DEFAULT 0,
  `posy` int(11) NOT NULL DEFAULT 0,
  `posz` int(11) NOT NULL DEFAULT 0,
  `lookbody` int(11) NOT NULL DEFAULT 0,
  `lookfeet` int(11) NOT NULL DEFAULT 0,
  `lookhead` int(11) NOT NULL DEFAULT 0,
  `looklegs` int(11) NOT NULL DEFAULT 0,
  `looktype` int(11) NOT NULL DEFAULT 136
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estrutura da tabela `player_inboxitems`
--

CREATE TABLE `player_inboxitems` (
  `player_id` int(11) NOT NULL,
  `sid` int(11) NOT NULL,
  `pid` int(11) NOT NULL DEFAULT 0,
  `itemtype` int(11) NOT NULL DEFAULT 0,
  `count` int(11) NOT NULL DEFAULT 0,
  `attributes` blob NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Estrutura da tabela `player_items`
--

CREATE TABLE `player_items` (
  `player_id` int(11) NOT NULL DEFAULT 0,
  `pid` int(11) NOT NULL DEFAULT 0,
  `sid` int(11) NOT NULL DEFAULT 0,
  `itemtype` int(11) NOT NULL DEFAULT 0,
  `count` int(11) NOT NULL DEFAULT 0,
  `attributes` blob NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Extraindo dados da tabela `player_items`
--

INSERT INTO `player_items` (`player_id`, `pid`, `sid`, `itemtype`, `count`, `attributes`) VALUES
(6, 3, 101, 1987, 1, 0x2601),
(6, 4, 102, 2651, 1, ''),
(6, 6, 103, 2382, 1, ''),
(6, 10, 104, 2050, 1, ''),
(6, 11, 105, 26052, 1, ''),
(6, 101, 106, 7618, 1, 0x0f01),
(6, 101, 107, 7589, 1, 0x0f01),
(6, 101, 108, 7588, 1, 0x0f01),
(6, 101, 109, 7588, 1, 0x0f01),
(6, 101, 110, 2493, 1, ''),
(6, 101, 111, 2674, 1, 0x0f01),
(6, 105, 112, 16101, 1, 0x04d71b0744005573696e672074686973207363726f6c6c2077696c6c206164642033302064617973206f66207669702074696d6520746f20796f7572206163636f756e74206f6e63652e),
(6, 105, 113, 16101, 1, 0x04d71b0744005573696e672074686973207363726f6c6c2077696c6c206164642033302064617973206f66207669702074696d6520746f20796f7572206163636f756e74206f6e63652e),
(6, 105, 114, 16101, 1, 0x04d71b0744005573696e672074686973207363726f6c6c2077696c6c206164642033302064617973206f66207669702074696d6520746f20796f7572206163636f756e74206f6e63652e),
(5, 3, 101, 1987, 1, ''),
(5, 4, 102, 2651, 1, ''),
(5, 6, 103, 2382, 1, ''),
(5, 11, 104, 26052, 1, '');

-- --------------------------------------------------------

--
-- Estrutura da tabela `player_kills`
--

CREATE TABLE `player_kills` (
  `player_id` int(11) NOT NULL,
  `time` bigint(20) UNSIGNED NOT NULL DEFAULT 0,
  `target` int(11) NOT NULL,
  `unavenged` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Estrutura da tabela `player_marketing`
--

CREATE TABLE `player_marketing` (
  `player_id` int(11) NOT NULL DEFAULT 0,
  `player_name` varchar(32) NOT NULL,
  `uid` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `subitem` varchar(32) NOT NULL,
  `itemtype` smallint(5) UNSIGNED NOT NULL DEFAULT 0,
  `count` smallint(6) NOT NULL DEFAULT 0,
  `price` bigint(20) NOT NULL DEFAULT 0,
  `rarity` smallint(6) NOT NULL DEFAULT 0,
  `attributes` blob NOT NULL,
  `completed` varchar(32) NOT NULL DEFAULT 'false'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estrutura da tabela `player_marketing_lua`
--

CREATE TABLE `player_marketing_lua` (
  `player_name` varchar(32) NOT NULL,
  `uid` varchar(32) NOT NULL,
  `data` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estrutura da tabela `player_marketing_reward`
--

CREATE TABLE `player_marketing_reward` (
  `player_name` varchar(32) NOT NULL,
  `uid` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `reward` bigint(20) NOT NULL DEFAULT 0,
  `completed` varchar(32) NOT NULL DEFAULT 'false'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estrutura da tabela `player_marketing_reward_lua`
--

CREATE TABLE `player_marketing_reward_lua` (
  `id` int(11) NOT NULL,
  `player_name` varchar(32) NOT NULL,
  `amount` bigint(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estrutura da tabela `player_misc`
--

CREATE TABLE `player_misc` (
  `player_id` int(11) NOT NULL,
  `info` blob NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Estrutura da tabela `player_namelocks`
--

CREATE TABLE `player_namelocks` (
  `player_id` int(11) NOT NULL,
  `reason` varchar(255) NOT NULL,
  `namelocked_at` bigint(20) NOT NULL,
  `namelocked_by` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Estrutura da tabela `player_prey`
--

CREATE TABLE `player_prey` (
  `player_id` int(11) NOT NULL,
  `name` varchar(50) NOT NULL,
  `mindex` smallint(6) NOT NULL,
  `mcolumn` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Estrutura da tabela `player_preydata`
--

CREATE TABLE `player_preydata` (
  `player_id` int(11) NOT NULL,
  `data` blob NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Extraindo dados da tabela `player_preydata`
--

INSERT INTO `player_preydata` (`player_id`, `data`) VALUES
(5, 0x00000000000000000003090e00446565706c696e672047756172640f00446565706c696e6720547972616e740a00476c6f6f6d20576f6c6616004869676820566f6c7461676520456c656d656e74616c0a0049636520447261676f6e0800496e6b20426c6f620e0052697070657220537065637472650600536962616e670b005377616e204d616964656e0100000000000000000309150042617262617269616e20426c6f6f6477616c6b6572030042617416004372617a65642053756d6d65722056616e67756172640f00446565706c696e6720576f726b6572110044776f72632056656e6f6d736e697065720600456672656574100048756d6f6e676f75732046756e6775730e004c6f7374204265727365726b65720b0053616e64637261776c65720200000000000000000000),
(6, 0x000000000000000000030903004261740d004272696d73746f6e6520427567110044776f726320466c65736868756e7465720a004669726520446576696c0c00496e73616e6520536972656e08004f6d6e69766f7261160052656e65676164652051756172612050696e636865720b005377616e204d616964656e120054686f726e6261636b20546f72746f69736501000000000000000003090e0041726163686e6f70686f626963610400426561720a00446561746820426c6f620f00446565706c696e6720576f726b65720e00476c6f6f746820426174746572790b004772696d205265617065720d0048697665204f766572736565721100496e737461626c6520537061726b696f6e0f00576174657220456c656d656e74616c0200000000000000000000);

-- --------------------------------------------------------

--
-- Estrutura da tabela `player_preytimes`
--

CREATE TABLE `player_preytimes` (
  `player_id` int(11) NOT NULL,
  `bonus_type1` int(11) NOT NULL,
  `bonus_value1` int(11) NOT NULL,
  `bonus_name1` varchar(50) NOT NULL,
  `bonus_type2` int(11) NOT NULL,
  `bonus_value2` int(11) NOT NULL,
  `bonus_name2` varchar(50) NOT NULL,
  `bonus_type3` int(11) NOT NULL,
  `bonus_value3` int(11) NOT NULL,
  `bonus_name3` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Estrutura da tabela `player_rewards`
--

CREATE TABLE `player_rewards` (
  `player_id` int(11) NOT NULL,
  `sid` int(11) NOT NULL,
  `pid` int(11) NOT NULL DEFAULT 0,
  `itemtype` int(11) NOT NULL DEFAULT 0,
  `count` int(11) NOT NULL DEFAULT 0,
  `attributes` blob NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Estrutura da tabela `player_spells`
--

CREATE TABLE `player_spells` (
  `player_id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Estrutura da tabela `player_storage`
--

CREATE TABLE `player_storage` (
  `player_id` int(11) NOT NULL DEFAULT 0,
  `key` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `value` int(11) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Estrutura da tabela `prey_slots`
--

CREATE TABLE `prey_slots` (
  `player_id` int(11) NOT NULL,
  `num` smallint(2) NOT NULL,
  `state` smallint(2) NOT NULL DEFAULT 1,
  `unlocked` tinyint(1) NOT NULL DEFAULT 0,
  `current` varchar(40) NOT NULL DEFAULT '',
  `monster_list` varchar(360) NOT NULL,
  `free_reroll_in` int(11) NOT NULL DEFAULT 0,
  `time_left` smallint(5) NOT NULL DEFAULT 0,
  `next_use` int(11) NOT NULL DEFAULT 0,
  `bonus_type` smallint(3) NOT NULL,
  `bonus_value` smallint(3) NOT NULL DEFAULT 0,
  `bonus_grade` smallint(3) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Estrutura da tabela `sellchar`
--

CREATE TABLE `sellchar` (
  `id` int(11) NOT NULL,
  `name` varchar(40) NOT NULL,
  `vocation` int(11) NOT NULL,
  `price` int(11) NOT NULL,
  `status` varchar(40) NOT NULL,
  `oldid` varchar(40) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Estrutura da tabela `sell_players`
--

CREATE TABLE `sell_players` (
  `player_id` int(11) NOT NULL,
  `account` int(11) NOT NULL,
  `create` bigint(20) NOT NULL,
  `createip` bigint(20) NOT NULL,
  `coin` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Estrutura da tabela `sell_players_history`
--

CREATE TABLE `sell_players_history` (
  `player_id` int(11) NOT NULL,
  `accountold` int(11) NOT NULL,
  `accountnew` int(11) NOT NULL,
  `create` bigint(20) NOT NULL,
  `createip` bigint(20) NOT NULL,
  `buytime` bigint(20) NOT NULL,
  `buyip` bigint(20) NOT NULL,
  `coin` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Estrutura da tabela `server_config`
--

CREATE TABLE `server_config` (
  `config` varchar(50) NOT NULL,
  `value` varchar(256) NOT NULL DEFAULT ''
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Extraindo dados da tabela `server_config`
--

INSERT INTO `server_config` (`config`, `value`) VALUES
('boost_monster', '0'),
('boost_monster_name', ''),
('boost_monster_url', ''),
('db_version', '38'),
('motd_hash', '815194dfb446b52a3e94f39defd8f2cef3fb2863'),
('motd_num', '2'),
('players_record', '2');

-- --------------------------------------------------------

--
-- Estrutura da tabela `snowballwar`
--

CREATE TABLE `snowballwar` (
  `id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `score` int(11) NOT NULL,
  `data` varchar(255) NOT NULL,
  `hora` varchar(255) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Estrutura da tabela `store_history`
--

CREATE TABLE `store_history` (
  `accountid` int(11) NOT NULL,
  `mode` tinyint(1) NOT NULL DEFAULT 0,
  `amount` int(11) NOT NULL,
  `coinMode` tinyint(2) NOT NULL DEFAULT 0,
  `description` varchar(255) DEFAULT NULL,
  `cust` int(11) NOT NULL,
  `time` bigint(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Extraindo dados da tabela `store_history`
--

INSERT INTO `store_history` (`accountid`, `mode`, `amount`, `coinMode`, `description`, `cust`, `time`) VALUES
(1, 0, 1, 0, '30 Days of VIP Time', -250, 1751562288),
(1, 0, 1, 0, '30 Days of VIP Time', -250, 1751562292),
(1, 0, 1, 0, '30 Days of VIP Time', -250, 1751565781);

-- --------------------------------------------------------

--
-- Estrutura da tabela `store_history_old`
--

CREATE TABLE `store_history_old` (
  `account_id` int(11) NOT NULL,
  `mode` smallint(2) NOT NULL DEFAULT 0,
  `description` varchar(3500) NOT NULL,
  `coin_amount` int(12) NOT NULL,
  `time` bigint(20) UNSIGNED NOT NULL,
  `timestamp` int(11) NOT NULL DEFAULT 0,
  `id` int(11) NOT NULL,
  `coins` int(11) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Estrutura da tabela `tickets`
--

CREATE TABLE `tickets` (
  `ticket_id` int(11) NOT NULL,
  `ticket_subject` varchar(255) DEFAULT NULL,
  `ticket_author` varchar(255) DEFAULT NULL,
  `ticket_author_acc_id` int(11) NOT NULL,
  `ticket_last_reply` varchar(11) DEFAULT NULL,
  `ticket_admin_reply` int(11) DEFAULT NULL,
  `ticket_date` varchar(255) DEFAULT NULL,
  `ticket_ended` varchar(255) DEFAULT NULL,
  `ticket_status` varchar(255) DEFAULT NULL,
  `ticket_category` varchar(255) DEFAULT NULL,
  `ticket_description` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Estrutura da tabela `tickets_reply`
--

CREATE TABLE `tickets_reply` (
  `reply_id` int(11) NOT NULL,
  `ticket_id` int(11) DEFAULT NULL,
  `reply_author` varchar(255) DEFAULT NULL,
  `reply_message` varchar(255) DEFAULT NULL,
  `reply_date` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Estrutura da tabela `tile_store`
--

CREATE TABLE `tile_store` (
  `house_id` int(11) NOT NULL,
  `data` longblob NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

--
-- Extraindo dados da tabela `tile_store`
--

INSERT INTO `tile_store` (`house_id`, `data`) VALUES
(1, 0xa50063010601000000de0600),
(1, 0xa70062010601000000241900),
(1, 0xa50064010601000000df0600),
(1, 0xa70067010601000000c50400),
(2, 0xa4006a010601000000c50400),
(2, 0xa0006c010601000000251900),
(2, 0xa1006d010601000000dc0600),
(2, 0xa2006d010601000000dd0600),
(3, 0xa10063010601000000de0600),
(3, 0xa20062010601000000241900),
(3, 0xa00065010601000000251900),
(3, 0xa10064010601000000df0600),
(3, 0xa30067010601000000c50400),
(4, 0xfb00e1010c01000000f61300),
(4, 0xfd00e1010b01000000f31300),
(4, 0xff00e1010b01000000da0600),
(4, 0xff00e2010b01000000db0600),
(5, 0xdf002f020501000000de0600),
(5, 0xde0030020501000000251900),
(5, 0xdf0030020501000000df0600),
(5, 0xe40030020501000000c30400),
(6, 0xe400e1010b01000000da0600),
(6, 0xe400e2010b01000000db0600),
(6, 0xe600e1010b01000000f31300),
(6, 0xe800e1010c01000000f61300),
(7, 0x85005c0104010000002c1900),
(7, 0x87005f010401000000da0600),
(7, 0x8400600104010000006f1800),
(7, 0x870060010401000000db0600),
(8, 0x6f005e0107010000002d1900),
(8, 0x72005b0107010000002c1900),
(8, 0x70005c010701000000da0600),
(8, 0x70005d010701000000db0600),
(8, 0x74005d0107010000006f1800),
(8, 0x6f00610107010000002d1900),
(9, 0x6f005e0106010000002d1900),
(9, 0x72005b0106010000002c1900),
(9, 0x76005e0106010000002c1900),
(9, 0x76005f010601000000e00600),
(9, 0x77005f010601000000e10600),
(9, 0x6f00610106010000002d1900),
(9, 0x720063010601000000711800),
(9, 0x740061010601000000691800),
(9, 0x760062010601000000e00600),
(9, 0x770062010601000000e10600),
(10, 0x6f005e0105010000002d1900),
(10, 0x72005b0105010000002c1900),
(10, 0x70005c010501000000e00600),
(10, 0x71005c010501000000e10600),
(10, 0x6f00610105010000002d1900),
(10, 0x7400610105010000006f1800),
(11, 0x82006b0106010000006f1800),
(11, 0x870069010601000000da0600),
(11, 0x87006a010601000000db0600),
(11, 0x82006c0106010000002d1900),
(12, 0x82006b0105010000002d1900),
(12, 0x8500680105010000002c1900),
(12, 0x860068010501000000711800),
(12, 0x83006d010501000000e00600),
(12, 0x84006d010501000000e10600),
(13, 0x6e0077010701000000dc0600),
(13, 0x6f0077010701000000dd0600),
(13, 0x710079010701000000bd0400),
(13, 0x74007b010701000000c30400),
(14, 0x6d0087010701000000251900),
(14, 0x6b008b010601000000251900),
(14, 0x6e0088010601000000bd0400),
(14, 0x6d008c010601000000dc0600),
(14, 0x6e008c010601000000dd0600),
(14, 0x710085010601000000241900),
(14, 0x700085010701000000241900),
(14, 0x730087010701000000c30400),
(15, 0x940077010701000000c30400),
(15, 0x980075010701000000de0600),
(15, 0x980076010701000000df0600),
(15, 0x940078010701000000251900),
(16, 0x94007d010701000000251900),
(16, 0x94007e010701000000c30400),
(16, 0x98007e010701000000de0600),
(16, 0x98007f010701000000df0600),
(17, 0x94008a010701000000251900),
(17, 0x950089010701000000de0600),
(17, 0x95008a010701000000df0600),
(17, 0x94008e010701000000251900),
(17, 0x97008f010701000000c50400),
(18, 0x960095010701000000241900),
(18, 0x970095010701000000c50400),
(18, 0x940098010701000000dc0600),
(18, 0x950098010701000000dd0600),
(19, 0x9c008c010701000000de0600),
(19, 0x9c008d010701000000df0600),
(19, 0x9f008f010701000000c50400),
(20, 0x9f0099010701000000de0600),
(20, 0x9f009a010701000000df0600),
(20, 0xa20095010701000000c50400),
(20, 0xa30095010701000000241900),
(23, 0x6f009a0107010000002c1900),
(23, 0x6c009d010701000000da0600),
(23, 0x6c009e010701000000db0600),
(23, 0x70009a0107010000002c1900),
(23, 0x72009e0107010000006f1800),
(24, 0x6c009d010601000000da0600),
(24, 0x6c009e010601000000db0600),
(24, 0x72009e0106010000006f1800),
(25, 0xbd0065010701000000da0600),
(25, 0xbd0066010701000000db0600),
(25, 0xc10069010701000000711800),
(26, 0xbd0065010601000000da0600),
(26, 0xbd0066010601000000db0600),
(26, 0xc10069010601000000711800),
(27, 0x9f0096010601000000dc0600),
(27, 0x9e0099010601000000251900),
(27, 0xa00096010601000000dd0600),
(27, 0xa20095010601000000241900),
(27, 0xa50099010601000000c30400),
(28, 0xaf008a0106010000002d1900),
(28, 0xaf008e0106010000002d1900),
(28, 0xb300870106010000002c1900),
(28, 0xb40088010601000000da0600),
(28, 0xb40089010601000000db0600),
(28, 0xb1008f010601000000711800),
(29, 0xb3009b0105010000002d1900),
(29, 0xb3009b0106010000002d1900),
(29, 0xb500980105010000002c1900),
(29, 0xb3009c0106010000006f1800),
(29, 0xb4009d010501000000e00600),
(29, 0xb5009d010501000000e10600),
(30, 0xba00960104010000002c1900),
(30, 0xbf00960105010000002c1900),
(30, 0xb700980104010000001a0700),
(30, 0xb700990104010000001a0700),
(30, 0xb7009b0104010000002d1900),
(30, 0xbc0098010401000000691800),
(30, 0xbc009c010401000000691800),
(30, 0xbe009e0105010000006c1800),
(30, 0xbc00a1010501000000dc0600),
(30, 0xbd00a1010501000000dd0600),
(30, 0xbf00a1010501000000dc0600),
(30, 0xc000960104010000002c1900),
(30, 0xc10096010501000000711800),
(30, 0xc3009b010401000000691800),
(30, 0xc3009c0104010000002d1900),
(30, 0xc000a1010501000000dd0600),
(31, 0xa0006d010701000000251900),
(31, 0xa1006d010701000000dc0600),
(31, 0xa2006d010701000000dd0600),
(31, 0xa5006c010701000000c30400),
(32, 0xa10067010701000000dc0600),
(32, 0xa20067010701000000dd0600),
(32, 0xa00068010701000000251900),
(32, 0xa50068010701000000c30400),
(33, 0xa10063010701000000dc0600),
(33, 0xa20063010701000000dd0600),
(33, 0xa00064010701000000251900),
(33, 0xa50065010701000000c30400),
(34, 0xa90067010701000000de0600),
(34, 0xa90068010701000000df0600),
(34, 0xab006a010701000000c50400),
(35, 0xb3006b010701000000dc0600),
(35, 0xb4006b010701000000dd0600),
(35, 0xb0006c010701000000c30400),
(36, 0xb30067010701000000dc0600),
(36, 0xb40067010701000000dd0600),
(36, 0xb00068010701000000c30400),
(37, 0xb30063010701000000dc0600),
(37, 0xb40063010701000000dd0600),
(37, 0xb00064010701000000c30400),
(38, 0xa90063010701000000dc0600),
(38, 0xaa0063010701000000dd0600),
(38, 0xab0062010701000000241900),
(38, 0xad0065010701000000c30400),
(39, 0xb30062010601000000241900),
(39, 0xb40063010601000000de0600),
(39, 0xb00065010601000000c30400),
(39, 0xb40064010601000000df0600),
(40, 0xb40067010601000000de0600),
(40, 0xb00068010601000000c30400),
(40, 0xb40068010601000000df0600),
(41, 0xb4006b010601000000de0600),
(41, 0xb0006c010601000000c30400),
(41, 0xb4006c010601000000df0600),
(42, 0xaa006a010601000000c50400),
(42, 0xa8006d010601000000dc0600),
(42, 0xa9006d010601000000dd0600),
(43, 0xaa0063010601000000de0600),
(43, 0xab0062010601000000241900),
(43, 0xaa0064010601000000df0600),
(43, 0xab0067010601000000c50400),
(44, 0x0401da010b01000000ea1300),
(44, 0x0401d8010c01000000ed1300),
(44, 0x0401dc010b01000000e00600),
(44, 0x0501dc010b01000000e10600),
(45, 0x0a01da010b01000000ea1300),
(45, 0x0a01d8010c01000000ed1300),
(45, 0x0a01dc010b01000000e00600),
(45, 0x0b01dc010b01000000e10600),
(46, 0x0f01d5010b01000000f31300),
(46, 0x0d01d5010c01000000f61300),
(46, 0x1101d5010b01000000da0600),
(46, 0x1101d6010b01000000db0600),
(47, 0x0f01cf010b01000000f31300),
(47, 0x0d01cf010c01000000f61300),
(47, 0x1101cf010b01000000da0600),
(47, 0x1101d0010b01000000db0600),
(48, 0x0f01c9010b01000000f31300),
(48, 0x0d01c9010c01000000f61300),
(48, 0x1101c9010b01000000da0600),
(48, 0x1101ca010b01000000db0600),
(49, 0x0a01c1010b01000000e00600),
(49, 0x0a01c3010b01000000ea1300),
(49, 0x0b01c1010b01000000e10600),
(49, 0x0a01c5010c01000000ed1300),
(50, 0x0401c1010b01000000e00600),
(50, 0x0401c3010b01000000ea1300),
(50, 0x0501c1010b01000000e10600),
(50, 0x0401c5010c01000000ed1300),
(51, 0xe000da010b01000000ea1300),
(51, 0xe000d8010c01000000ed1300),
(51, 0xe000dc010b01000000e00600),
(51, 0xe100dc010b01000000e10600),
(52, 0xda00da010b01000000ea1300),
(52, 0xda00d8010c01000000ed1300),
(52, 0xda00dc010b01000000e00600),
(52, 0xdb00dc010b01000000e10600),
(53, 0xd200d5010b01000000da0600),
(53, 0xd200d6010b01000000db0600),
(53, 0xd400d5010b01000000f31300),
(53, 0xd600d5010c01000000f61300),
(54, 0xd200cf010b01000000da0600),
(54, 0xd400cf010b01000000f31300),
(54, 0xd600cf010c01000000f61300),
(54, 0xd200d0010b01000000db0600),
(55, 0xd200c9010b01000000da0600),
(55, 0xd200ca010b01000000db0600),
(55, 0xd400c9010b01000000f31300),
(55, 0xd600c9010c01000000f61300),
(56, 0xda00c1010b01000000e00600),
(56, 0xda00c3010b01000000ea1300),
(56, 0xdb00c1010b01000000e10600),
(56, 0xda00c5010c01000000ed1300),
(57, 0xe000c1010b01000000e00600),
(57, 0xe000c3010b01000000ea1300),
(57, 0xe100c1010b01000000e10600),
(57, 0xe000c5010c01000000ed1300),
(58, 0xde00b6010c01000000b90400),
(58, 0xdb00b8010b01000000bc0400),
(58, 0xde00bb010c01000000b90400),
(58, 0xd900bd010b01000000e00600),
(58, 0xda00bd010b01000000e10600),
(58, 0xdb00bd010b01000000e00600),
(58, 0xdc00bd010b01000000e10600),
(58, 0xde00bd010b01000000e00600),
(58, 0xdf00bd010b01000000e10600),
(58, 0xde00bc010c010000001a0700),
(58, 0xe200b6010b01000000b90400),
(58, 0xe500b7010c01000000c30400),
(58, 0xe000b8010b01000000bc0400),
(58, 0xe300b9010c01000000bc0400),
(58, 0xe000bd010b01000000e00600),
(58, 0xe100bd010b01000000e10600),
(59, 0xfe00b5010c010000001a0700),
(59, 0xfe00bc010c01000000c30400),
(59, 0x0101b6010b01000000b90400),
(59, 0x0401b5010c01000000b90400),
(59, 0x0101b9010c01000000bc0400),
(59, 0x0401b8010b01000000bc0400),
(59, 0x0901b8010b01000000bc0400),
(59, 0x0201bd010b01000000e00600),
(59, 0x0301bd010b01000000e10600),
(59, 0x0401bd010b01000000e00600),
(59, 0x0501bd010b01000000e10600),
(59, 0x0701bd010b01000000e00600),
(59, 0x0401bc010c01000000b90400),
(59, 0x0801bd010b01000000e10600),
(59, 0x0a01bd010b01000000e00600),
(59, 0x0b01bd010b01000000e10600),
(60, 0xe50021020601000000dc0600),
(60, 0xe60021020601000000dd0600),
(60, 0xe70025020601000000c50400),
(61, 0xe00021020601000000dc0600),
(61, 0xe10021020601000000dd0600),
(61, 0xe20020020601000000241900),
(61, 0xe20025020601000000c50400),
(62, 0xf2002a020601000000c30400),
(62, 0xf50028020601000000241900),
(62, 0xf60029020601000000de0600),
(62, 0xf6002a020601000000df0600),
(63, 0xeb002b020601000000241900),
(63, 0xe9002f020601000000dc0600),
(63, 0xea002f020601000000dd0600),
(63, 0xed002e020601000000c30400),
(64, 0xf2002e020601000000c30400),
(64, 0xf5002d020601000000dc0600),
(64, 0xf6002d020601000000dd0600),
(65, 0xeb002b020501000000241900),
(65, 0xe8002e020501000000c30400),
(65, 0xec002c020501000000de0600),
(65, 0xec002d020501000000df0600),
(66, 0xdf002b020501000000dc0600),
(66, 0xde002c020501000000251900),
(66, 0xdf002d020501000000dc0600),
(66, 0xe0002b020501000000dd0600),
(66, 0xe1002a020501000000241900),
(66, 0xe0002d020501000000dd0600),
(66, 0xe4002d020501000000c30400),
(67, 0xab01eb000601000000721b00),
(67, 0xac01e9000601000000dc0600),
(67, 0xad01e9000601000000dd0600),
(67, 0xae01e8000601000000711b00),
(67, 0xae01ed000601000000ee1a00),
(68, 0x9b01e6000701000000de0600),
(68, 0x9b01e7000701000000df0600),
(68, 0x9b01eb000701000000eb1a00),
(68, 0x9d01ed000701000000f71a00),
(69, 0x9a01d1000601000000711b00),
(69, 0x9c01d2000601000000dc0600),
(69, 0x9d01d2000601000000dd0600),
(69, 0x9c01d1000701000000711b00),
(69, 0x9b01d5000601000000f41a00),
(69, 0x9e01d4000701000000f71a00),
(70, 0x9401d7000601000000dc0600),
(70, 0x9501d6000601000000841a00),
(70, 0x9501d7000601000000dd0600),
(70, 0x9501d90006010000008b1a00),
(70, 0x9601dd000601000000901b00),
(71, 0x8701e6000601000000851a00),
(71, 0x8801e7000601000000dc0600),
(71, 0x8901e7000601000000dd0600),
(71, 0x8b01e50006010000008d1a00),
(71, 0x8f01e50006010000008e1b00),
(72, 0x8601d7000501000000dc0600),
(72, 0x8701d6000501000000841a00),
(72, 0x8701d7000501000000dd0600),
(72, 0x8501d9000501000000851a00),
(72, 0x8601da000501000000dc0600),
(72, 0x8701da000501000000dd0600),
(72, 0x8a01da0005010000008d1a00),
(72, 0x8e01da000501000000851a00),
(72, 0x8c01dd000501000000841a00),
(72, 0x8d01dd000501000000901b00),
(73, 0xad01d2000601000000de0600),
(73, 0xad01d3000601000000df0600),
(73, 0xb101d3000601000000f41a00),
(73, 0xb401d1000601000000ee1a00),
(74, 0xb601cf000601000000f71a00),
(74, 0xb701d3000601000000de0600),
(74, 0xb901d1000601000000eb1a00),
(74, 0xba01d3000601000000de0600),
(74, 0xb701d4000601000000df0600),
(74, 0xba01d4000601000000df0600),
(75, 0xac01c1000701000000de0600),
(75, 0xac01c2000701000000df0600),
(75, 0xb101c3000701000000f71a00),
(76, 0xdf01be000701000000f71a00),
(76, 0xdf01bf000701000000721b00),
(76, 0xe401bb000701000000de0600),
(76, 0xe401bc000701000000df0600),
(77, 0xe301b7000701000000f71a00),
(77, 0xe301b8000701000000741b00),
(77, 0xe601bb000701000000dc0600),
(77, 0xe701bb000701000000dd0600),
(78, 0xe701b1000601000000e00600),
(78, 0xe801b1000601000000e10600),
(78, 0xeb01b0000601000000851b00),
(79, 0xb901bb000701000000de0600),
(79, 0xb901bc000701000000df0600),
(79, 0xb801c0000701000000ee1a00),
(80, 0xbb01bb000701000000dc0600),
(80, 0xbc01bb000701000000dd0600),
(80, 0xbc01be000701000000eb1a00),
(80, 0xbe01c3000701000000ee1a00),
(81, 0xbf01bd000701000000dc0600),
(81, 0xc001bd000701000000dd0600),
(81, 0xc101bc000701000000f41a00),
(81, 0xc301bf000701000000ee1a00),
(82, 0xbe01cc000701000000721b00),
(82, 0xc401c9000701000000ee1a00),
(82, 0xc501c9000701000000711b00),
(82, 0xc501ce000701000000eb1a00),
(82, 0xc701cf000701000000de0600),
(82, 0xc301d0000701000000721b00),
(82, 0xc601d1000701000000dc0600),
(82, 0xc701d0000701000000df0600),
(82, 0xc701d1000701000000dd0600),
(83, 0xc701ba000701000000dc0600),
(83, 0xc801ba000701000000dd0600),
(83, 0xc701bf000701000000ee1a00),
(84, 0xce01c8000701000000f71a00),
(84, 0xce01c9000701000000721b00),
(84, 0xd201c5000701000000711b00),
(84, 0xd401c8000701000000de0600),
(84, 0xd401c9000701000000df0600),
(85, 0xbb01bb000601000000dc0600),
(85, 0xbc01bb000601000000dd0600),
(85, 0xbe01ba000601000000711b00),
(85, 0xbf01bb000601000000dc0600),
(85, 0xbe01bf000601000000ee1a00),
(85, 0xc001bb000601000000dd0600),
(86, 0xd501b4000701000000dc0600),
(86, 0xd601b4000701000000dd0600),
(86, 0xda01b7000701000000f71a00),
(87, 0xda01af000701000000f71a00),
(87, 0xd501b2000701000000dc0600),
(87, 0xd601b2000701000000dd0600),
(88, 0xd201a6000701000000dc0600),
(88, 0xd301a6000701000000dd0600),
(88, 0xd201ab000701000000dc0600),
(88, 0xd301ab000701000000dd0600),
(88, 0xd801a8000701000000f71a00),
(89, 0xd301a1000701000000de0600),
(89, 0xd301a2000701000000df0600),
(89, 0xda01a3000701000000f71a00),
(90, 0xd5019c000701000000de0600),
(90, 0xd5019d000701000000df0600),
(90, 0xda019e000701000000f71a00),
(91, 0xd301a6000601000000721b00),
(91, 0xd801a4000601000000f71a00),
(91, 0xd301aa000601000000721b00),
(91, 0xd401aa000601000000de0600),
(91, 0xd401ab000601000000df0600),
(91, 0xd601a8000601000000eb1a00),
(91, 0xd701aa000601000000de0600),
(91, 0xd701ab000601000000df0600),
(92, 0xd7019b000601000000711b00),
(92, 0xd401a1000601000000de0600),
(92, 0xd401a2000601000000df0600),
(92, 0xd601a0000601000000eb1a00),
(92, 0xd901a0000601000000ee1a00),
(93, 0xe0019f000701000000721b00),
(93, 0xe3019f000701000000620600),
(93, 0xe6019f000701000000f41a00),
(93, 0xe7019d000701000000dc0600),
(93, 0xe8019d000701000000dd0600),
(93, 0xe001a0000701000000f71a00),
(94, 0xab01c3000601000000f71a00),
(94, 0xaf01c0000601000000711b00),
(94, 0xab01c4000601000000721b00),
(94, 0xb001c4000601000000de0600),
(94, 0xb001c5000601000000df0600),
(95, 0xa901b9000601000000711b00),
(95, 0xab01ba000601000000de0600),
(95, 0xab01bb000601000000df0600),
(95, 0xa901bf000601000000ee1a00),
(96, 0xa301ba000601000000dc0600),
(96, 0xa401ba000601000000dd0600),
(96, 0xa501b9000601000000711b00),
(96, 0xa201bc000601000000721b00),
(96, 0xa501bf000601000000ee1a00),
(97, 0xb401b3000701000000e00600),
(97, 0xb501b3000701000000e10600),
(97, 0xb401b5000701000000791b00),
(97, 0xb601b7000701000000851b00),
(98, 0xb401b6000601000000791b00),
(98, 0xb501b7000601000000da0600),
(98, 0xb601b5000601000000851b00),
(98, 0xb501b8000601000000db0600),
(99, 0xce01b3000501000000821b00),
(99, 0xcc01b7000501000000791b00),
(99, 0xce01b9000501000000851b00),
(99, 0xd201b2000501000000da0600),
(99, 0xd201b3000501000000db0600),
(100, 0xce019b000601000000821b00),
(100, 0xd10199000601000000da0600),
(100, 0xd1019a000601000000db0600),
(101, 0x6c0089010701000000e00600),
(101, 0x6d0089010701000000e10600),
(101, 0x6c008c010701000000e00600),
(101, 0x6d008c010701000000e10600),
(101, 0x73008b010701000000c30400),
(102, 0x6d008f010701000000251900),
(102, 0x720089010601000000da0600),
(102, 0x72008a010601000000db0600),
(102, 0x71008d010601000000bd0400),
(102, 0x73008f010701000000c30400),
(103, 0x7b00930107010000002d1900),
(103, 0x7f0095010701000000711800),
(103, 0x810091010701000000de0600),
(103, 0x810092010701000000df0600),
(104, 0x7a008d0107010000002d1900),
(104, 0x7a008e0107010000006f1800),
(104, 0x7d008d010701000000620600),
(104, 0x81008b010701000000e00600),
(104, 0x82008b010701000000e10600),
(104, 0x80008d0107010000006a1800),
(104, 0x81008f010701000000e00600),
(104, 0x82008f010701000000e10600),
(105, 0x7d007e010701000000711800),
(105, 0x83007f0107010000002c1900),
(105, 0x7a00820107010000002d1900),
(105, 0x7d00840106010000006d1800),
(105, 0x7d00840107010000006d1800),
(105, 0x7b00880107010000002d1900),
(105, 0x810080010501000000e00600),
(105, 0x810083010501000000e00600),
(105, 0x820080010501000000e10600),
(105, 0x820083010501000000e10600),
(105, 0x830083010501000000e00600),
(105, 0x8000820106010000006a1800),
(105, 0x800081010701000000691800),
(105, 0x8000830107010000001a0700),
(105, 0x840083010501000000e10600),
(105, 0x8000870106010000006a1800),
(105, 0x830085010601000000e00600),
(105, 0x830086010601000000e00600),
(105, 0x830087010601000000e00600),
(105, 0x8300850107010000006d1800),
(105, 0x840085010601000000e10600),
(105, 0x840086010601000000e10600),
(105, 0x840087010601000000e10600),
(105, 0x830088010601000000e00600),
(105, 0x830089010601000000e00600),
(105, 0x8000880107010000006a1800),
(105, 0x840088010601000000e10600),
(105, 0x840089010601000000e10600),
(106, 0x88007d010701000000711800),
(106, 0x89007d0107010000002c1900),
(106, 0x890081010701000000e00600),
(106, 0x8a0081010701000000e10600),
(107, 0x860083010701000000de0600),
(107, 0x860084010701000000df0600),
(107, 0x8800850107010000006d1800),
(107, 0x8b00840107010000006a1800),
(107, 0x8b0085010701000000130700),
(107, 0x8d00850107010000006c1800),
(107, 0x8e00870107010000006f1800),
(108, 0x9c0094010701000000241900),
(108, 0x9e0094010701000000c50400),
(108, 0x9c0098010701000000bc0400),
(108, 0x9c009a010701000000dc0600),
(108, 0x9d009a010701000000dd0600),
(109, 0x6b00570107010000002c1900),
(109, 0x69005b0107010000002d1900),
(109, 0x6a0058010701000000da0600),
(109, 0x6a0059010701000000db0600),
(109, 0x6f00590107010000006f1800),
(110, 0x6f004f0107010000002c1900),
(110, 0x6f00520107010000006d1800),
(110, 0x6d00550107010000002d1900),
(110, 0x700050010701000000da0600),
(110, 0x700051010701000000db0600),
(110, 0x7300550107010000006f1800),
(111, 0xb5007b010601000000e00600),
(111, 0xb6007b010601000000e10600),
(111, 0xba007a010601000000711800),
(111, 0xb5007e010601000000e00600),
(111, 0xb6007e010601000000e10600),
(111, 0xb7007d0106010000006a1800),
(112, 0xb70073010601000000da0600),
(112, 0xb400740106010000002d1900),
(112, 0xb600750106010000006c1800),
(112, 0xb70074010601000000db0600),
(112, 0xb800780106010000006f1800);

-- --------------------------------------------------------

--
-- Estrutura da tabela `z_forum`
--

CREATE TABLE `z_forum` (
  `id` int(11) NOT NULL,
  `first_post` int(11) NOT NULL DEFAULT 0,
  `last_post` int(11) NOT NULL DEFAULT 0,
  `section` int(3) NOT NULL DEFAULT 0,
  `replies` int(20) NOT NULL DEFAULT 0,
  `views` int(20) NOT NULL DEFAULT 0,
  `author_aid` int(20) NOT NULL DEFAULT 0,
  `author_guid` int(20) NOT NULL DEFAULT 0,
  `post_text` text NOT NULL,
  `post_topic` varchar(255) NOT NULL,
  `post_smile` tinyint(1) NOT NULL DEFAULT 0,
  `post_date` int(20) NOT NULL DEFAULT 0,
  `last_edit_aid` int(20) NOT NULL DEFAULT 0,
  `edit_date` int(20) NOT NULL DEFAULT 0,
  `post_ip` varchar(15) NOT NULL DEFAULT '0.0.0.0',
  `icon_id` int(11) NOT NULL,
  `news_icon` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Estrutura da tabela `z_network_box`
--

CREATE TABLE `z_network_box` (
  `id` int(11) NOT NULL,
  `network_name` varchar(10) NOT NULL,
  `network_link` varchar(50) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Estrutura da tabela `z_news_tickers`
--

CREATE TABLE `z_news_tickers` (
  `date` int(11) NOT NULL DEFAULT 1,
  `author` int(11) NOT NULL,
  `image_id` int(3) NOT NULL DEFAULT 0,
  `text` text NOT NULL,
  `hide_ticker` tinyint(1) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Estrutura da tabela `z_ots_comunication`
--

CREATE TABLE `z_ots_comunication` (
  `id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `type` varchar(255) NOT NULL,
  `action` varchar(255) NOT NULL,
  `param1` varchar(255) NOT NULL,
  `param2` varchar(255) NOT NULL,
  `param3` varchar(255) NOT NULL,
  `param4` varchar(255) NOT NULL,
  `param5` varchar(255) NOT NULL,
  `param6` varchar(255) NOT NULL,
  `param7` varchar(255) NOT NULL,
  `delete_it` int(2) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Estrutura da tabela `z_ots_guildcomunication`
--

CREATE TABLE `z_ots_guildcomunication` (
  `id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `type` varchar(255) NOT NULL,
  `action` varchar(255) NOT NULL,
  `param1` varchar(255) NOT NULL,
  `param2` varchar(255) NOT NULL,
  `param3` varchar(255) NOT NULL,
  `param4` varchar(255) NOT NULL,
  `param5` varchar(255) NOT NULL,
  `param6` varchar(255) NOT NULL,
  `param7` varchar(255) NOT NULL,
  `delete_it` int(2) NOT NULL DEFAULT 1
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Estrutura da tabela `z_polls`
--

CREATE TABLE `z_polls` (
  `id` int(11) NOT NULL,
  `question` varchar(255) NOT NULL,
  `end` int(11) NOT NULL,
  `start` int(11) NOT NULL,
  `answers` int(11) NOT NULL,
  `votes_all` int(11) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Estrutura da tabela `z_polls_answers`
--

CREATE TABLE `z_polls_answers` (
  `poll_id` int(11) NOT NULL,
  `answer_id` int(11) NOT NULL,
  `answer` varchar(255) NOT NULL,
  `votes` int(11) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Estrutura da tabela `z_replay`
--

CREATE TABLE `z_replay` (
  `title` varchar(255) DEFAULT NULL,
  `version` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Estrutura da tabela `z_shop_category`
--

CREATE TABLE `z_shop_category` (
  `id` int(11) NOT NULL,
  `name` varchar(50) NOT NULL,
  `desc` varchar(255) NOT NULL,
  `button` varchar(50) NOT NULL,
  `hide` int(11) NOT NULL DEFAULT 0
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Estrutura da tabela `z_shop_donates`
--

CREATE TABLE `z_shop_donates` (
  `id` int(11) NOT NULL,
  `date` bigint(20) NOT NULL,
  `reference` varchar(50) NOT NULL,
  `account_name` varchar(50) NOT NULL,
  `method` varchar(50) NOT NULL,
  `price` varchar(20) NOT NULL,
  `coins` int(11) NOT NULL,
  `status` varchar(20) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Estrutura da tabela `z_shop_donate_confirm`
--

CREATE TABLE `z_shop_donate_confirm` (
  `id` int(11) NOT NULL,
  `date` bigint(20) NOT NULL,
  `account_name` varchar(50) NOT NULL,
  `donate_id` int(11) NOT NULL,
  `msg` text NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Estrutura da tabela `z_shop_history_item`
--

CREATE TABLE `z_shop_history_item` (
  `id` int(11) NOT NULL,
  `to_name` varchar(255) NOT NULL DEFAULT '0',
  `to_account` int(11) NOT NULL DEFAULT 0,
  `from_nick` varchar(255) NOT NULL,
  `from_account` int(11) NOT NULL DEFAULT 0,
  `price` int(11) NOT NULL DEFAULT 0,
  `offer_id` varchar(255) NOT NULL DEFAULT '',
  `trans_state` varchar(255) NOT NULL,
  `trans_start` int(11) NOT NULL DEFAULT 0,
  `trans_real` int(11) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Estrutura da tabela `z_shop_offer`
--

CREATE TABLE `z_shop_offer` (
  `id` int(11) NOT NULL,
  `category` int(11) NOT NULL,
  `coins` int(11) NOT NULL DEFAULT 0,
  `price` varchar(50) NOT NULL,
  `itemid` int(11) NOT NULL DEFAULT 0,
  `mount_id` varchar(100) NOT NULL,
  `addon_name` varchar(100) NOT NULL,
  `count` int(11) NOT NULL DEFAULT 0,
  `offer_type` varchar(255) DEFAULT NULL,
  `offer_description` text NOT NULL,
  `offer_name` varchar(255) NOT NULL,
  `offer_date` int(11) NOT NULL,
  `default_image` varchar(50) NOT NULL,
  `hide` int(11) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Estrutura da tabela `z_shop_payment`
--

CREATE TABLE `z_shop_payment` (
  `id` int(11) NOT NULL,
  `ref` varchar(10) NOT NULL,
  `account_name` varchar(50) NOT NULL,
  `service_id` int(11) NOT NULL,
  `service_category_id` int(11) NOT NULL,
  `payment_method_id` int(11) NOT NULL,
  `price` varchar(50) NOT NULL,
  `coins` int(11) UNSIGNED NOT NULL,
  `status` varchar(50) NOT NULL DEFAULT 'waiting',
  `date` int(11) NOT NULL,
  `gift` int(11) NOT NULL DEFAULT 0
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Índices para tabelas despejadas
--

--
-- Índices para tabela `accounts`
--
ALTER TABLE `accounts`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `name` (`name`),
  ADD UNIQUE KEY `name_2` (`name`),
  ADD UNIQUE KEY `name_3` (`name`),
  ADD UNIQUE KEY `name_4` (`name`);

--
-- Índices para tabela `accounts_storage`
--
ALTER TABLE `accounts_storage`
  ADD PRIMARY KEY (`account_id`,`key`);

--
-- Índices para tabela `account_bans`
--
ALTER TABLE `account_bans`
  ADD PRIMARY KEY (`account_id`),
  ADD KEY `banned_by` (`banned_by`);

--
-- Índices para tabela `account_ban_history`
--
ALTER TABLE `account_ban_history`
  ADD PRIMARY KEY (`id`),
  ADD KEY `account_id` (`account_id`),
  ADD KEY `banned_by` (`banned_by`),
  ADD KEY `account_id_2` (`account_id`),
  ADD KEY `account_id_3` (`account_id`),
  ADD KEY `account_id_4` (`account_id`),
  ADD KEY `account_id_5` (`account_id`),
  ADD KEY `account_id_6` (`account_id`);

--
-- Índices para tabela `account_character_sale`
--
ALTER TABLE `account_character_sale`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `id_player_UNIQUE` (`id_player`),
  ADD KEY `account_character_sale_ibfk_2` (`id_account`);

--
-- Índices para tabela `account_viplist`
--
ALTER TABLE `account_viplist`
  ADD UNIQUE KEY `account_player_index` (`account_id`,`player_id`),
  ADD KEY `account_id` (`account_id`),
  ADD KEY `player_id` (`player_id`);

--
-- Índices para tabela `auto_loot_list`
--
ALTER TABLE `auto_loot_list`
  ADD PRIMARY KEY (`id`),
  ADD KEY `player_id` (`player_id`);

--
-- Índices para tabela `blessings_history`
--
ALTER TABLE `blessings_history`
  ADD KEY `blessings_history_ibfk_1` (`player_id`);

--
-- Índices para tabela `boost_creature`
--
ALTER TABLE `boost_creature`
  ADD PRIMARY KEY (`category`,`name`);

--
-- Índices para tabela `daily_reward_history`
--
ALTER TABLE `daily_reward_history`
  ADD PRIMARY KEY (`id`),
  ADD KEY `player_id` (`player_id`);

--
-- Índices para tabela `free_pass`
--
ALTER TABLE `free_pass`
  ADD KEY `free_pass_ibfk_1` (`player_id`);

--
-- Índices para tabela `global_storage`
--
ALTER TABLE `global_storage`
  ADD UNIQUE KEY `key` (`key`);

--
-- Índices para tabela `guilds`
--
ALTER TABLE `guilds`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `name` (`name`),
  ADD UNIQUE KEY `ownerid` (`ownerid`);

--
-- Índices para tabela `guildwar_kills`
--
ALTER TABLE `guildwar_kills`
  ADD PRIMARY KEY (`id`),
  ADD KEY `warid` (`warid`);

--
-- Índices para tabela `guild_actions_h`
--
ALTER TABLE `guild_actions_h`
  ADD PRIMARY KEY (`id`);

--
-- Índices para tabela `guild_invites`
--
ALTER TABLE `guild_invites`
  ADD PRIMARY KEY (`player_id`,`guild_id`),
  ADD KEY `guild_id` (`guild_id`);

--
-- Índices para tabela `guild_membership`
--
ALTER TABLE `guild_membership`
  ADD PRIMARY KEY (`player_id`),
  ADD KEY `guild_id` (`guild_id`),
  ADD KEY `rank_id` (`rank_id`);

--
-- Índices para tabela `guild_ranks`
--
ALTER TABLE `guild_ranks`
  ADD PRIMARY KEY (`id`),
  ADD KEY `guild_id` (`guild_id`);

--
-- Índices para tabela `guild_transfer_h`
--
ALTER TABLE `guild_transfer_h`
  ADD PRIMARY KEY (`id`);

--
-- Índices para tabela `guild_wars`
--
ALTER TABLE `guild_wars`
  ADD PRIMARY KEY (`id`),
  ADD KEY `guild1` (`guild1`),
  ADD KEY `guild2` (`guild2`);

--
-- Índices para tabela `houses`
--
ALTER TABLE `houses`
  ADD PRIMARY KEY (`id`),
  ADD KEY `owner` (`owner`),
  ADD KEY `town_id` (`town_id`);

--
-- Índices para tabela `house_lists`
--
ALTER TABLE `house_lists`
  ADD KEY `house_id` (`house_id`);

--
-- Índices para tabela `ip_bans`
--
ALTER TABLE `ip_bans`
  ADD PRIMARY KEY (`ip`),
  ADD KEY `banned_by` (`banned_by`);

--
-- Índices para tabela `live_casts`
--
ALTER TABLE `live_casts`
  ADD UNIQUE KEY `player_id_2` (`player_id`);

--
-- Índices para tabela `market_history`
--
ALTER TABLE `market_history`
  ADD PRIMARY KEY (`id`),
  ADD KEY `player_id` (`player_id`,`sale`);

--
-- Índices para tabela `market_offers`
--
ALTER TABLE `market_offers`
  ADD PRIMARY KEY (`id`),
  ADD KEY `sale` (`sale`,`itemtype`),
  ADD KEY `created` (`created`),
  ADD KEY `player_id` (`player_id`);

--
-- Índices para tabela `newsticker`
--
ALTER TABLE `newsticker`
  ADD PRIMARY KEY (`id`);

--
-- Índices para tabela `pagseguro_transactions`
--
ALTER TABLE `pagseguro_transactions`
  ADD UNIQUE KEY `transaction_code` (`transaction_code`,`status`),
  ADD KEY `name` (`name`),
  ADD KEY `status` (`status`);

--
-- Índices para tabela `players`
--
ALTER TABLE `players`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `name` (`name`),
  ADD KEY `account_id` (`account_id`),
  ADD KEY `vocation` (`vocation`);

--
-- Índices para tabela `players_online`
--
ALTER TABLE `players_online`
  ADD PRIMARY KEY (`player_id`);

--
-- Índices para tabela `player_binary_items`
--
ALTER TABLE `player_binary_items`
  ADD UNIQUE KEY `player_id_2` (`player_id`,`type`);

--
-- Índices para tabela `player_deaths`
--
ALTER TABLE `player_deaths`
  ADD KEY `player_id` (`player_id`),
  ADD KEY `killed_by` (`killed_by`),
  ADD KEY `mostdamage_by` (`mostdamage_by`);

--
-- Índices para tabela `player_depotitems`
--
ALTER TABLE `player_depotitems`
  ADD UNIQUE KEY `player_id_2` (`player_id`,`sid`);

--
-- Índices para tabela `player_former_names`
--
ALTER TABLE `player_former_names`
  ADD PRIMARY KEY (`id`),
  ADD KEY `player_id` (`player_id`);

--
-- Índices para tabela `player_hirelings`
--
ALTER TABLE `player_hirelings`
  ADD PRIMARY KEY (`id`),
  ADD KEY `player_id` (`player_id`);

--
-- Índices para tabela `player_inboxitems`
--
ALTER TABLE `player_inboxitems`
  ADD UNIQUE KEY `player_id_2` (`player_id`,`sid`);

--
-- Índices para tabela `player_items`
--
ALTER TABLE `player_items`
  ADD KEY `player_id` (`player_id`),
  ADD KEY `sid` (`sid`);

--
-- Índices para tabela `player_kills`
--
ALTER TABLE `player_kills`
  ADD KEY `player_kills_ibfk_1` (`player_id`),
  ADD KEY `player_kills_ibfk_2` (`target`);

--
-- Índices para tabela `player_marketing`
--
ALTER TABLE `player_marketing`
  ADD KEY `player_id` (`player_id`);

--
-- Índices para tabela `player_marketing_lua`
--
ALTER TABLE `player_marketing_lua`
  ADD PRIMARY KEY (`player_name`,`uid`);

--
-- Índices para tabela `player_marketing_reward_lua`
--
ALTER TABLE `player_marketing_reward_lua`
  ADD PRIMARY KEY (`id`);

--
-- Índices para tabela `player_namelocks`
--
ALTER TABLE `player_namelocks`
  ADD PRIMARY KEY (`player_id`),
  ADD KEY `namelocked_by` (`namelocked_by`);

--
-- Índices para tabela `player_preydata`
--
ALTER TABLE `player_preydata`
  ADD PRIMARY KEY (`player_id`);

--
-- Índices para tabela `player_rewards`
--
ALTER TABLE `player_rewards`
  ADD UNIQUE KEY `player_id_2` (`player_id`,`sid`);

--
-- Índices para tabela `player_spells`
--
ALTER TABLE `player_spells`
  ADD KEY `player_id` (`player_id`);

--
-- Índices para tabela `player_storage`
--
ALTER TABLE `player_storage`
  ADD PRIMARY KEY (`player_id`,`key`);

--
-- Índices para tabela `prey_slots`
--
ALTER TABLE `prey_slots`
  ADD KEY `player_id` (`player_id`);

--
-- Índices para tabela `sellchar`
--
ALTER TABLE `sellchar`
  ADD PRIMARY KEY (`id`);

--
-- Índices para tabela `sell_players`
--
ALTER TABLE `sell_players`
  ADD PRIMARY KEY (`player_id`);

--
-- Índices para tabela `sell_players_history`
--
ALTER TABLE `sell_players_history`
  ADD PRIMARY KEY (`player_id`,`buytime`) USING BTREE;

--
-- Índices para tabela `server_config`
--
ALTER TABLE `server_config`
  ADD PRIMARY KEY (`config`);

--
-- Índices para tabela `snowballwar`
--
ALTER TABLE `snowballwar`
  ADD PRIMARY KEY (`id`),
  ADD KEY `id` (`id`);

--
-- Índices para tabela `store_history`
--
ALTER TABLE `store_history`
  ADD KEY `store_history_ibfk_1` (`accountid`);

--
-- Índices para tabela `store_history_old`
--
ALTER TABLE `store_history_old`
  ADD KEY `account_id` (`account_id`);

--
-- Índices para tabela `tickets`
--
ALTER TABLE `tickets`
  ADD PRIMARY KEY (`ticket_id`),
  ADD KEY `tickets_ibfk_1` (`ticket_author_acc_id`);

--
-- Índices para tabela `tickets_reply`
--
ALTER TABLE `tickets_reply`
  ADD PRIMARY KEY (`reply_id`),
  ADD KEY `tickets_reply_ibfk_1` (`ticket_id`);

--
-- Índices para tabela `tile_store`
--
ALTER TABLE `tile_store`
  ADD KEY `house_id` (`house_id`);

--
-- Índices para tabela `z_forum`
--
ALTER TABLE `z_forum`
  ADD PRIMARY KEY (`id`),
  ADD KEY `section` (`section`);

--
-- Índices para tabela `z_ots_comunication`
--
ALTER TABLE `z_ots_comunication`
  ADD PRIMARY KEY (`id`);

--
-- Índices para tabela `z_ots_guildcomunication`
--
ALTER TABLE `z_ots_guildcomunication`
  ADD PRIMARY KEY (`id`);

--
-- Índices para tabela `z_shop_category`
--
ALTER TABLE `z_shop_category`
  ADD PRIMARY KEY (`id`);

--
-- Índices para tabela `z_shop_donates`
--
ALTER TABLE `z_shop_donates`
  ADD PRIMARY KEY (`id`);

--
-- Índices para tabela `z_shop_donate_confirm`
--
ALTER TABLE `z_shop_donate_confirm`
  ADD PRIMARY KEY (`id`);

--
-- Índices para tabela `z_shop_offer`
--
ALTER TABLE `z_shop_offer`
  ADD PRIMARY KEY (`id`);

--
-- Índices para tabela `z_shop_payment`
--
ALTER TABLE `z_shop_payment`
  ADD PRIMARY KEY (`id`);

--
-- AUTO_INCREMENT de tabelas despejadas
--

--
-- AUTO_INCREMENT de tabela `accounts`
--
ALTER TABLE `accounts`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8421;

--
-- AUTO_INCREMENT de tabela `account_ban_history`
--
ALTER TABLE `account_ban_history`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=25;

--
-- AUTO_INCREMENT de tabela `account_character_sale`
--
ALTER TABLE `account_character_sale`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=563;

--
-- AUTO_INCREMENT de tabela `auto_loot_list`
--
ALTER TABLE `auto_loot_list`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de tabela `daily_reward_history`
--
ALTER TABLE `daily_reward_history`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=75041;

--
-- AUTO_INCREMENT de tabela `guilds`
--
ALTER TABLE `guilds`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=87;

--
-- AUTO_INCREMENT de tabela `guildwar_kills`
--
ALTER TABLE `guildwar_kills`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=667;

--
-- AUTO_INCREMENT de tabela `guild_actions_h`
--
ALTER TABLE `guild_actions_h`
  MODIFY `id` int(6) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de tabela `guild_ranks`
--
ALTER TABLE `guild_ranks`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=269;

--
-- AUTO_INCREMENT de tabela `guild_transfer_h`
--
ALTER TABLE `guild_transfer_h`
  MODIFY `id` int(6) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de tabela `guild_wars`
--
ALTER TABLE `guild_wars`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=15;

--
-- AUTO_INCREMENT de tabela `houses`
--
ALTER TABLE `houses`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2501;

--
-- AUTO_INCREMENT de tabela `market_history`
--
ALTER TABLE `market_history`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=201750;

--
-- AUTO_INCREMENT de tabela `market_offers`
--
ALTER TABLE `market_offers`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=63544;

--
-- AUTO_INCREMENT de tabela `newsticker`
--
ALTER TABLE `newsticker`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=42;

--
-- AUTO_INCREMENT de tabela `players`
--
ALTER TABLE `players`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11910;

--
-- AUTO_INCREMENT de tabela `player_former_names`
--
ALTER TABLE `player_former_names`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de tabela `player_hirelings`
--
ALTER TABLE `player_hirelings`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de tabela `player_marketing_reward_lua`
--
ALTER TABLE `player_marketing_reward_lua`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de tabela `sellchar`
--
ALTER TABLE `sellchar`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de tabela `snowballwar`
--
ALTER TABLE `snowballwar`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de tabela `tickets`
--
ALTER TABLE `tickets`
  MODIFY `ticket_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=443;

--
-- AUTO_INCREMENT de tabela `tickets_reply`
--
ALTER TABLE `tickets_reply`
  MODIFY `reply_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=408;

--
-- AUTO_INCREMENT de tabela `z_forum`
--
ALTER TABLE `z_forum`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=27;

--
-- AUTO_INCREMENT de tabela `z_ots_comunication`
--
ALTER TABLE `z_ots_comunication`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de tabela `z_ots_guildcomunication`
--
ALTER TABLE `z_ots_guildcomunication`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de tabela `z_shop_category`
--
ALTER TABLE `z_shop_category`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT de tabela `z_shop_donates`
--
ALTER TABLE `z_shop_donates`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=878;

--
-- AUTO_INCREMENT de tabela `z_shop_donate_confirm`
--
ALTER TABLE `z_shop_donate_confirm`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=239;

--
-- AUTO_INCREMENT de tabela `z_shop_offer`
--
ALTER TABLE `z_shop_offer`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de tabela `z_shop_payment`
--
ALTER TABLE `z_shop_payment`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- Restrições para despejos de tabelas
--

--
-- Limitadores para a tabela `accounts_storage`
--
ALTER TABLE `accounts_storage`
  ADD CONSTRAINT `accounts_storage_ibfk_1` FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`) ON DELETE CASCADE;

--
-- Limitadores para a tabela `account_bans`
--
ALTER TABLE `account_bans`
  ADD CONSTRAINT `account_bans_ibfk_1` FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `account_bans_ibfk_2` FOREIGN KEY (`banned_by`) REFERENCES `players` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Limitadores para a tabela `account_ban_history`
--
ALTER TABLE `account_ban_history`
  ADD CONSTRAINT `account_ban_history_ibfk_2` FOREIGN KEY (`banned_by`) REFERENCES `players` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `account_ban_history_ibfk_3` FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `account_ban_history_ibfk_4` FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `account_ban_history_ibfk_5` FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `account_ban_history_ibfk_6` FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `account_ban_history_ibfk_7` FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Limitadores para a tabela `account_character_sale`
--
ALTER TABLE `account_character_sale`
  ADD CONSTRAINT `account_character_sale_ibfk_1` FOREIGN KEY (`id_player`) REFERENCES `players` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `account_character_sale_ibfk_2` FOREIGN KEY (`id_account`) REFERENCES `accounts` (`id`) ON DELETE CASCADE;

--
-- Limitadores para a tabela `account_viplist`
--
ALTER TABLE `account_viplist`
  ADD CONSTRAINT `account_viplist_ibfk_1` FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `account_viplist_ibfk_2` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE;

--
-- Limitadores para a tabela `auto_loot_list`
--
ALTER TABLE `auto_loot_list`
  ADD CONSTRAINT `auto_loot_list_ibfk_1` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Limitadores para a tabela `blessings_history`
--
ALTER TABLE `blessings_history`
  ADD CONSTRAINT `blessings_history_ibfk_1` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE;

--
-- Limitadores para a tabela `free_pass`
--
ALTER TABLE `free_pass`
  ADD CONSTRAINT `free_pass_ibfk_1` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE;

--
-- Limitadores para a tabela `guilds`
--
ALTER TABLE `guilds`
  ADD CONSTRAINT `guilds_ibfk_1` FOREIGN KEY (`ownerid`) REFERENCES `players` (`id`) ON DELETE CASCADE;

--
-- Limitadores para a tabela `guildwar_kills`
--
ALTER TABLE `guildwar_kills`
  ADD CONSTRAINT `guildwar_kills_ibfk_1` FOREIGN KEY (`warid`) REFERENCES `guild_wars` (`id`) ON DELETE CASCADE;

--
-- Limitadores para a tabela `guild_invites`
--
ALTER TABLE `guild_invites`
  ADD CONSTRAINT `guild_invites_ibfk_1` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `guild_invites_ibfk_2` FOREIGN KEY (`guild_id`) REFERENCES `guilds` (`id`) ON DELETE CASCADE;

--
-- Limitadores para a tabela `guild_membership`
--
ALTER TABLE `guild_membership`
  ADD CONSTRAINT `guild_membership_ibfk_1` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `guild_membership_ibfk_2` FOREIGN KEY (`guild_id`) REFERENCES `guilds` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `guild_membership_ibfk_3` FOREIGN KEY (`rank_id`) REFERENCES `guild_ranks` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Limitadores para a tabela `guild_ranks`
--
ALTER TABLE `guild_ranks`
  ADD CONSTRAINT `guild_ranks_ibfk_1` FOREIGN KEY (`guild_id`) REFERENCES `guilds` (`id`) ON DELETE CASCADE;

--
-- Limitadores para a tabela `house_lists`
--
ALTER TABLE `house_lists`
  ADD CONSTRAINT `house_lists_ibfk_1` FOREIGN KEY (`house_id`) REFERENCES `houses` (`id`) ON DELETE CASCADE;

--
-- Limitadores para a tabela `ip_bans`
--
ALTER TABLE `ip_bans`
  ADD CONSTRAINT `ip_bans_ibfk_1` FOREIGN KEY (`banned_by`) REFERENCES `players` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Limitadores para a tabela `live_casts`
--
ALTER TABLE `live_casts`
  ADD CONSTRAINT `live_casts_ibfk_1` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE;

--
-- Limitadores para a tabela `market_history`
--
ALTER TABLE `market_history`
  ADD CONSTRAINT `market_history_ibfk_1` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE;

--
-- Limitadores para a tabela `market_offers`
--
ALTER TABLE `market_offers`
  ADD CONSTRAINT `market_offers_ibfk_1` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE;

--
-- Limitadores para a tabela `players`
--
ALTER TABLE `players`
  ADD CONSTRAINT `players_ibfk_1` FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`) ON DELETE CASCADE;

--
-- Limitadores para a tabela `player_binary_items`
--
ALTER TABLE `player_binary_items`
  ADD CONSTRAINT `player_binary_items_ibfk_1` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE;

--
-- Limitadores para a tabela `player_deaths`
--
ALTER TABLE `player_deaths`
  ADD CONSTRAINT `player_deaths_ibfk_1` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE;

--
-- Limitadores para a tabela `player_depotitems`
--
ALTER TABLE `player_depotitems`
  ADD CONSTRAINT `player_depotitems_ibfk_1` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE;

--
-- Limitadores para a tabela `player_hirelings`
--
ALTER TABLE `player_hirelings`
  ADD CONSTRAINT `player_hirelings_ibfk_1` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE;

--
-- Limitadores para a tabela `player_inboxitems`
--
ALTER TABLE `player_inboxitems`
  ADD CONSTRAINT `player_inboxitems_ibfk_1` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE;

--
-- Limitadores para a tabela `player_items`
--
ALTER TABLE `player_items`
  ADD CONSTRAINT `player_items_ibfk_1` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE;

--
-- Limitadores para a tabela `player_kills`
--
ALTER TABLE `player_kills`
  ADD CONSTRAINT `player_kills_ibfk_1` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `player_kills_ibfk_2` FOREIGN KEY (`target`) REFERENCES `players` (`id`) ON DELETE CASCADE;

--
-- Limitadores para a tabela `player_marketing`
--
ALTER TABLE `player_marketing`
  ADD CONSTRAINT `player_marketing_ibfk_1` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE;

--
-- Limitadores para a tabela `player_namelocks`
--
ALTER TABLE `player_namelocks`
  ADD CONSTRAINT `player_namelocks_ibfk_1` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `player_namelocks_ibfk_2` FOREIGN KEY (`namelocked_by`) REFERENCES `players` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Limitadores para a tabela `player_preydata`
--
ALTER TABLE `player_preydata`
  ADD CONSTRAINT `player_preydata_ibfk_1` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Limitadores para a tabela `player_rewards`
--
ALTER TABLE `player_rewards`
  ADD CONSTRAINT `player_rewards_ibfk_1` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE;

--
-- Limitadores para a tabela `player_spells`
--
ALTER TABLE `player_spells`
  ADD CONSTRAINT `player_spells_ibfk_1` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE;

--
-- Limitadores para a tabela `player_storage`
--
ALTER TABLE `player_storage`
  ADD CONSTRAINT `player_storage_ibfk_1` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE;

--
-- Limitadores para a tabela `prey_slots`
--
ALTER TABLE `prey_slots`
  ADD CONSTRAINT `prey_slots_ibfk_1` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE;

--
-- Limitadores para a tabela `sellchar`
--
ALTER TABLE `sellchar`
  ADD CONSTRAINT `sellchar_ibfk_1` FOREIGN KEY (`id`) REFERENCES `players` (`id`) ON DELETE CASCADE;

--
-- Limitadores para a tabela `sell_players`
--
ALTER TABLE `sell_players`
  ADD CONSTRAINT `sell_players_ibfk_1` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE;

--
-- Limitadores para a tabela `sell_players_history`
--
ALTER TABLE `sell_players_history`
  ADD CONSTRAINT `sell_players_history_ibfk_1` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE;

--
-- Limitadores para a tabela `store_history`
--
ALTER TABLE `store_history`
  ADD CONSTRAINT `store_history_ibfk_1` FOREIGN KEY (`accountid`) REFERENCES `accounts` (`id`) ON DELETE CASCADE;

--
-- Limitadores para a tabela `store_history_old`
--
ALTER TABLE `store_history_old`
  ADD CONSTRAINT `store_history_old_ibfk_1` FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`) ON DELETE CASCADE;

--
-- Limitadores para a tabela `tickets`
--
ALTER TABLE `tickets`
  ADD CONSTRAINT `tickets_ibfk_1` FOREIGN KEY (`ticket_author_acc_id`) REFERENCES `accounts` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Limitadores para a tabela `tickets_reply`
--
ALTER TABLE `tickets_reply`
  ADD CONSTRAINT `tickets_reply_ibfk_1` FOREIGN KEY (`ticket_id`) REFERENCES `tickets` (`ticket_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Limitadores para a tabela `tile_store`
--
ALTER TABLE `tile_store`
  ADD CONSTRAINT `tile_store_ibfk_1` FOREIGN KEY (`house_id`) REFERENCES `houses` (`id`) ON DELETE CASCADE;

-- --------------------------------------------------------

--
-- Estrutura da tabela `roulette_plays`
--

CREATE TABLE IF NOT EXISTS `roulette_plays` (
  `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `player_id` int(11) NOT NULL,
  `uuid` VARCHAR(255) NOT NULL,
  `reward_id` int(11) NOT NULL,
  `reward_count` int(11) NOT NULL,
  `status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '0 = rolling | 1 = pending | 2 = delivered',
  `created_at` bigint(20) NOT NULL DEFAULT UNIX_TIMESTAMP(),
  `updated_at` bigint(20) NOT NULL DEFAULT UNIX_TIMESTAMP(),

  PRIMARY KEY (`id`),
  UNIQUE KEY (`uuid`),
  FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE 
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
