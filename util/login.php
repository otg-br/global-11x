<?php

require 'config/config.php';

// comment to show E_NOTICE [undefinied variable etc.], comment if you want make script and see all errors
error_reporting(E_ALL ^ E_STRICT ^ E_NOTICE);

// true = show sent queries and SQL queries status/status code/error message
define('DEBUG_DATABASE', false);
define('INITIALIZED', true);

if (!defined('ONLY_PAGE'))
    define('ONLY_PAGE', true);

$navegador = filter_input(INPUT_SERVER, "HTTP_USER_AGENT", FILTER_DEFAULT);
if ($navegador !== "Mozilla/5.0") {
	// header("Location: ./?subtopic=accountmanagement");
}

// check if site is disabled/requires installation
include_once('./system/load.loadCheck.php');

// fix user data, load config, enable class auto loader
include_once('./system/load.init.php');

// DATABASE
include_once('./system/load.database.php');
if (DEBUG_DATABASE)
    Website::getDBHandle()->setPrintQueries(true);

// DATABASE END

function create_char($player, $ismaincharacter) {
	$level = $player->getLevel();
	$outfitid = $player->getLookType();
	$headcolor = $player->getLookHead();
	$torsocolor = $player->getLookBody();
	$legscolor = $player->getLookLegs();
	$detailcolor = $player->getLookFeet();
	$addonflags = $player->getLookAddons();
	settype($level, "int");
	settype($outfitid, "int");
	settype($headcolor, "int"); 
	settype($torsocolor, "int"); 
	settype($legscolor, "int"); 
	settype($detailcolor, "int"); 
	settype($addonflags, "int"); 
	$char = array(
		"worldid" => 0, 
		"name" => $player->getName(), 
		"ismale" => (($player->getSex() == 1) ? true : false), 
		"tutorial" => false, 
		"outfitid" => $outfitid, 
		"level" => $level,
		"ismaincharacter" => $ismaincharacter,
		"headcolor" => $headcolor,
		"torsocolor" => $torsocolor,
		"legscolor" => $legscolor,
		"detailcolor" => $detailcolor,
		"addonsflags" => $addonflags,
		"vocation" => Website::getVocationName($player->getVocation()),
		'istournamentparticipant' => false,
		'remainingdailytournamentplaytime' => 0,
		"ishidden" => (($player->isHidden() == 1) ? true : false)
	);

	return $char;
}

function create_replay($replay) {
	$char = array(
		"worldid" => 0, 
		"name" => $replay["title"], 
		"ismale" => true, 
		"tutorial" => false, 
		"outfitid" => 128, 
		"level" => mt_rand(1, 1000),
		"ismaincharacter" => $replay["version"] > 1200 and true or false,
		"headcolor" => mt_rand(0, 255),
		"torsocolor" => mt_rand(0, 255),
		"legscolor" => mt_rand(0, 255),
		"detailcolor" => mt_rand(0, 255),
		"addonsflags" => mt_rand(0, 3),
		"vocation" => "Replay",
		'istournamentparticipant' => false,
		'remainingdailytournamentplaytime' => 0,
		"ishidden" => false
	);

	return $char;
}

function createEvent($event, $time)
{
	$ev = array(
		'startdate' => $event->getBeginTime($time),
		'enddate' => $event->getEndTime($time),
		'colorlight' => $event->getColorLight(),
		'colordark' => $event->getColorDark(),
		'name' => $event->getName(),
		'description' => $event->getDescription(),
		'isseasonal' => $event->isSeasonal()
	);

	return $ev;
}
$playersonline = $SQL->query("SELECT * FROM `players_online`")->fetchAll();
$input = json_decode(file_get_contents("php://input"));
switch ($input->type ? $input->type : '') {

    case "cacheinfo":
        $statistics = [
						'playersonline' => count($playersonline),
						'twitchstreams' => rand(0, 999),
						'twitchviewer' => rand(0, 999),
						'gamingyoutubestreams' => rand(0, 999),
						'gamingyoutubeviewer' => rand(0, 999)
					];
        echo json_encode($statistics);
    break;

    case "eventschedule":
		$campaign = array();
		$increment = 24*60*60;
		$max = 30;

	    $path = Website::getWebsiteConfig()->getValue('serverPath');
	    $events = new Events($path . 'data/XML/events.xml');

		for ($z = 1; $z <= $events->count(); $z++) {
			$event = $events->getEvent($z);
			$time = time();
			if ($event->getDay() < 9) {
				for ($i = 1; $i <= $max; $i++) {
					$diasemana_numero = date('w', $time);
					if ($event->getDay() == 8 || ($event->getDay() == $diasemana_numero) ) {
						$campaign[] = createEvent($event, $time);
					}
					$time += $increment;
				}
			} else {
				$campaign[] = createEvent($event, $time);
			}
		}

		$schedule['lastupdatetimestamp'] = time();
 		$schedule['eventlist'] = $campaign;
        echo json_encode($schedule);
        break;

    case "boostedcreature":
		// still name to figure out creature raceid's and work with server to boost the creature
    	$activeSql = $SQL->query("SELECT `value` FROM `server_config` WHERE `config` = 'boost_monster_name'")->fetch();
    	$active = $activeSql["value"] == 'none' and false or true;
		$boostedcreature["boostedcreature"] = true;
		$raceSql = $SQL->query("SELECT `value` FROM `server_config` WHERE `config` = 'boost_monster'")->fetch();
		// $raceid = 1820;
		$raceid = (int)$raceSql['value'];
		$boostedcreature["raceid"] = $raceid;
        echo json_encode($boostedcreature);
        break;
		
	case "login":


# Declare variables with array structure
$characters = array();
$playerData = array();
$data = array();
$isCasting = false;
$isReplay = false;

# error function
function sendError($msg){
    $ret = array();
    $ret["errorCode"] = 3;
    $ret["errorMessage"] = $msg;
    
    die(json_encode($ret));
}

function jsonError($message, $code = 3) {
	die(json_encode(array('errorCode' => $code, 'errorMessage' => $message)));
}

function sanitize($data) {
	return htmlentities(strip_tags($data));
}

# getting infos
	$request = file_get_contents('php://input');
	$result = json_decode($request, true);

# account infos
	$accountName = $result["accountname"];
	$password = $result["password"];
# game port
	$port = 7172;
	$location = "BRA";
	$configIp = $config['server']['ip'];


# check if player wanna see cast list
if (strtolower($accountName) == "cast")
	$isCasting = true;
if(strtolower($result["email"]) == "cast")
	$isCasting = true;

# check if player wanna see cast list
if (strtolower($accountName) == "replay")
	$isReplay = true;
if(strtolower($result["email"]) == "replay")
	$isReplay = true;
	
require_once("system/load.twoFactors.php");

if ($isCasting) {
	$casts = $SQL->query("SELECT `player_id` FROM `live_casts`")->fetchAll();
	if (count($casts[0]) == 0)
		sendError("There is no live casts right now!");
	foreach($casts as $cast) {
		$character = new Player();
		$character->load($cast['player_id']);
		
		if ($character->isLoaded()) {
			$characters[] = create_char($character, false);
		}	
	}
	$port = $config['server']['liveCastPort'];
	$lastLogin = 0;
	$premiumAccount = true;
	$timePremium = 0;
} else if ($isReplay) {
	$replays = $SQL->query("SELECT * FROM `z_replay`")->fetchAll();
	if (count($replays[0]) == 0)
		sendError("There is no replay right now!");
	foreach($replays as $replay) {
		$characters[] = create_replay($replay);
	}
	$port = $config['server']['replayProtocolPort'];
	$lastLogin = 0;
	$premiumAccount = true;
	$timePremium = 0;
} else {
	$account = new Account();
	$accountName = $result["email"];
	$account->loadByName($accountName);
	$current_password = Website::encryptPassword($password);
	if (!$account->isLoaded()) {
		sendError('Account name or password is not correct.');
	}

	if ($account->getPassword() != Website::encryptPassword($password)) {
		sendError("The password for this account is wrong. Try again!");
	}

	$token = (isset($result["token"])) ? filter_var($result["token"],FILTER_SANITIZE_NUMBER_INT) : false;
	$secretCode = $account->getSecretCode();
	if ($secretCode) {
		if ($token === false) {
			jsonError('Submit a valid two-factor authentication token.', 6);
		} else {
			if (TokenAuth6238::verify($secretCode, $token) !== true) {
				jsonError('Two-factor authentication failed, token is wrong.', 6);
			}
		}
	}
	
	$proxies = $config['server']['proxyList'];
	$exploded = explode(';', $proxies);
	foreach ($exploded as $proxy) {
		$info = explode(',', $proxy);
		if ($account->getProxyId() == (int) $info[0]) {
			$port = (int) $info[2];
			$configIp = $info[1];
			$location = $info[3];
			break;
		}
	}
	
	$hightlevel = 0;
	$playerlevelid = 0;
	foreach($account->getPlayersList() as $character) {
		if ($character->getLevel() > $hightlevel) {
			$hightlevel = $character->getLevel();
			$playerlevelid = $character->getID();
		}
	}
	
	foreach($account->getPlayersList() as $character) {
		$characters[] = create_char($character, $playerlevelid == $character->getID());
	}
	
	$lastLogin = $account->getLastLogin();
	$premiumAccount = (($config['server']['freePremium']) ? true : (($account->isPremium()) ? true : false));
	$timePremium = time() + (($account->getPremDays() + 654) * 86400);
}

$nameacc = strlen($accountName) < 3 ? $result["email"] : $accountName;

$sessionKey = $nameacc . "\n" . $password;
$sessionKey .= "\n".$token."\n".floor(time() / 30);

$session = array(
	"fpstracking" => false,
	"optiontracking" => false,
	"isreturner" => true,
	"returnernotification" => false,
	"showrewardnews" => false,
	"sessionkey" => $sessionKey ,
	"lastlogintime" => $lastLogin,
    "ispremium" => $premiumAccount,
    "premiumuntil" => (($config['server']['freePremium']) ? ((time() + 654)*86400) : $timePremium),
    "status" => "active",	
	"stayloggedin" => true,
	'tournamentticketpurchasestate' => 0,
	'emailcoderequest' => false
);

	if ($config['server']['worldType'] == "pvp") {
		$pvptype = 0;
	}
	else if ($config['server']['worldType'] == "no-pvp") {
		$pvptype = 1;
	}
	else if ($config['server']['worldType'] == "pvp-enforced") {
		$pvptype = 2;
	}
	else if ($config['server']['worldType'] == "retro-pvp") {
		$pvptype = 3;
	}
	else {
		$pvptype = 0; //default value
	}

$world = array(
	"id" => 0,
	"name" => $config['server']['serverName'],
	"externaladdress" => $configIp,
	"externalport" => $port,
	"previewstate" => 0,
    "location" => $location,
	"externaladdressunprotected" => $configIp,
	"externaladdressprotected" => $configIp,
	"externalportunprotected" => $port,
	"externalportprotected" => $port,
	"pvptype" => $pvptype,
	"anticheatprotection" => false,
	'istournamentworld' => false,
	'restrictedstore' => false,
	'currenttournamentphase' => 2
);



$worlds = array($world);
$data["session"] = $session;
$playerData["worlds"] = $worlds;
$playerData["characters"] = $characters;
$data["playdata"] = $playerData;
$data["survey"] = $survey;

echo json_encode($data);
}