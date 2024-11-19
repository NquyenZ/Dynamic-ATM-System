/*
	Dynamic ATM system for NGG gamemode and maybe work with Open.mp

	Created by: adewx (NquyenZ)
	
	Contact: https://facebook.com/nquyenZ.26

	Last Updated: 8:52PM 19/11/2024
*/

#include <YSI\y_hooks>

#define                SENDDATA_ATM            (1)
#define                ATM_FEE                 (80) // Player will receive 80% of their transaction if they have transaction fee
#define                BANK_HASH               "loveutn"

new
	PlayerInfo[MAX_PLAYERS][pInfo],
    AtmInfo[MAX_ATM][E_ATM];

enum pInfo
{
	pCash,
	pAccount,
	pSoTaiKhoan,
	pTenTaiKhoanNganHang[65],
	pAdmin,
	pInt,
	pVW,
	pMatKhauNganHang[65],
	pRobAtm
};

enum E_ATM
{
    ID,
    VirtualWorld,
    Float:Pos_X,
    Float:Pos_Y,
    Float:Pos_Z,
    Float:Rot_X,
    Float:Rot_Y,
    Float:Rot_Z,
    bool:Exists,
    PickupID,
    ObjectID,
    Float:ObjectHealth,
    Text3D:TextID,
    Money,
    RobTime
};

forward OnPlayerPickUpDynamicPickup(playerid, pickupid);
forward OnCreateAtmFinish(playerid, index, type);
forward OnLoadAtms();

task CoolDownATM[60000]() // Millisecond => 1 Minute
{
	for(new i = 0; i < MAX_ATM; i++)
	{
		if(AtmInfo[i][RobTime] > 0)
			AtmInfo[i][RobTime] --;
		else if(AtmInfo[i][RobTime])
			return 1;

		if(AtmInfo[i][ObjectHealth] != 300.0)
			AtmInfo[i][ObjectHealth] ++;
		else if(AtmInfo[i][ObjectHealth] == 300.0)
			return 1;
	}
	return 1;
}

task CoolDownPlayer[60000]()
{
	foreach(new i:Player)
		if(PlayerInfo[i][pRobAtm] > 0)
			PlayerInfo[i][pRobAtm] --;
		else if(PlayerInfo[i][pRobAtm] == 0)
			return 1;
	return 1;
}

public OnPlayerPickUpDynamicPickup(playerid, pickupid)
{
    for(new i = 0; i < MAX_ATM; i++)
    {
        if(IsPlayerInRangeOfPoint(playerid, 10.0, AtmInfo[i][Pos_X], AtmInfo[i][Pos_Y], AtmInfo[i][Pos_Z]))
        {
            if(pickupid == AtmInfo[i][PickupID])
            {
                new
                    receive = Random(2800, 4000);

                DestroyDynamicPickup(AtmInfo[i][PickupID]);

                if(AtmInfo[i][Money] >= receive)
                    AtmInfo[i][Money] -= receive;
                else if(AtmInfo[i][Money] < receive)
                    AtmInfo[i][Money] = 0;

                PlayerInfo[playerid][pRobAtm] = 120;

                Inventory_Add(playerid, "Dirty Money", receive);

                // >> Inventory_Add is my Inventory system function, so you can config that fit with your Inventory system << //

                SCMf(playerid, COLOR_WHITE, "You successfully robbed an {19AE61}ATM{FFFFFF} and got $%s Dirty Money", number_format(receive));

                ATM_Update(i);
            }
        }
    }
    return 1;
}

public OnLoadAtms()
{
	for(new i; i < MAX_ATM; i++)
	{
		AtmInfo[i][Exists] = false;
		AtmInfo[i][ObjectID] = INVALID_OBJECT_ID;
		AtmInfo[i][TextID] = INVALID_3DTEXT_ID;
	}

	new
		i,
		rows,
		fields,
		tmp[128];

	cache_get_data(rows, fields, MainPipeline);

	while(i < rows)
	{
		cache_get_field_content(i, "ID", tmp, MainPipeline); AtmInfo[i][ID] = strval(tmp);
		cache_get_field_content(i, "VirtualWorld", tmp, MainPipeline); AtmInfo[i][VirtualWorld] = strval(tmp);
		cache_get_field_content(i, "Pos_X", tmp, MainPipeline); AtmInfo[i][Pos_X] = floatstr(tmp);
		cache_get_field_content(i, "Pos_Y", tmp, MainPipeline); AtmInfo[i][Pos_Y] = floatstr(tmp);
		cache_get_field_content(i, "Pos_Z", tmp, MainPipeline); AtmInfo[i][Pos_Z] = floatstr(tmp);
		cache_get_field_content(i, "Rot_X", tmp, MainPipeline); AtmInfo[i][Rot_X] = floatstr(tmp);
		cache_get_field_content(i, "Rot_Y", tmp, MainPipeline); AtmInfo[i][Rot_Y] = floatstr(tmp);
		cache_get_field_content(i, "Rot_Z", tmp, MainPipeline); AtmInfo[i][Rot_Z] = floatstr(tmp);
		cache_get_field_content(i, "ObjectHealth", tmp, MainPipeline); AtmInfo[i][ObjectHealth] = floatstr(tmp);
		cache_get_field_content(i, "Money", tmp, MainPipeline); AtmInfo[i][Money] = strval(tmp);
		cache_get_field_content(i, "CoolDownTime", tmp, MainPipeline); AtmInfo[i][RobTime] = strval(tmp);

		AtmInfo[i][Exists] = true;

		ATM_Reload(i);

		i++;
	}

	if(i > 0)
		printf("[ATM System] %d ATM loaded", i);
}

public OnCreateAtmFinish(playerid, index, type)
{
	switch(type)
	{
		case SENDDATA_ATM:
		{
			AtmInfo[index][ID] = mysql_insert_id(MainPipeline);
			AtmInfo[index][Exists] = true;

			ATM_Reload(index);
		}
	}
	return 1;
}

public OnPlayerShootDynamicObject(playerid, weaponid, objectid, Float:x, Float:y, Float:z)
{
	new
        Float:damage;

    for(new i = 0; i < MAX_ATM; i++)
    {
        if(IsPlayerInRangeOfPoint(playerid, 10.0, AtmInfo[i][Pos_X], AtmInfo[i][Pos_Y], AtmInfo[i][Pos_Z]))
        {
            if(objectid == AtmInfo[i][ObjectID] && AtmInfo[i][ObjectHealth] > 0.0 && PlayerInfo[playerid][pRobAtm] == 0 && AtmInfo[i][RobTime] == 0)
            {
                switch(weaponid)
                {
                    case 22:
                        damage = 9.0;
                    case 23:
                        damage = 8.0;
                    case 24:
                        damage = 45.0;
                    case 25:
                        damage = 33.0;
                    case 29:
                        damage = 7.0;
                    case 30:
                        damage = 8.0;
                    case 31:
                        damage = 9.0;
                    case 33:
                        damage = 30.0;
                    case 34:
                        damage = 40.0;
                }

                AtmInfo[i][ObjectHealth] -= damage;

                SCMf(playerid, COLOR_GREY, "[DEBUG] %f", AtmInfo[i][ObjectHealth]);

                if(AtmInfo[i][ObjectHealth] <= 0.0)
                {
                    AtmInfo[i][ObjectHealth] = 0.0;
                    AtmInfo[i][RobTime] = 300;

                    ATM_Update(i);

                    AtmInfo[i][PickupID] = CreateDynamicPickup(1212, 23, AtmInfo[i][Pos_X] - 1.5, AtmInfo[i][Pos_Y], AtmInfo[i][Pos_Z], .worldid = AtmInfo[i][VirtualWorld]);
                }
            }
        }
    }
	return 1;
}

stock LoadATM()
{
	printf("[ATM System] Loading ATM data from Database...");

	mysql_function_query(MainPipeline, "SELECT * FROM atms", true, "OnLoadAtms", "");
}

stock GetFreeATM()
{
	for(new i = 0; i < MAX_ATM; i++)
		if(AtmInfo[i][Exists] == false)
			return i;
	return -1;
}

stock IsPlayerNearATM(playerid)
{
	new
		Float:Pos[3];

	GetPlayerPos(playerid, Pos[0], Pos[1], Pos[2]);

	for(new i = 0; i < MAX_ATM; i++)
		if(IsPlayerInRangeOfPoint(playerid, 3.0, AtmInfo[i][Pos_X], AtmInfo[i][Pos_Y], AtmInfo[i][Pos_Z]))
			return i;
	return -1;
}

stock ATM_Update(index)
{
	new
		string[2048];

	format(string, sizeof(string), "UPDATE `atms` SET \
		`VirtualWorld` = '%d', \
		`Pos_X` = '%f', \
		`Pos_Y` = '%f', \
		`Pos_Z` = '%f', \
		`Rot_X` = '%f', \
		`Rot_Y` = '%f', \
		`Rot_Z` = '%f', \
		`ObjectHealth` = '%f', \
		`Money` = '%d', \
		`CoolDownTime` = '%d' WHERE `ID` = '%d'",
		AtmInfo[index][VirtualWorld],
		AtmInfo[index][Pos_X],
		AtmInfo[index][Pos_Y],
		AtmInfo[index][Pos_Z],
		AtmInfo[index][Rot_X],
		AtmInfo[index][Rot_Y],
		AtmInfo[index][Rot_Z],
		AtmInfo[index][ObjectHealth],
		AtmInfo[index][Money],
		AtmInfo[index][RobTime],
		AtmInfo[index][ID]
	);

	mysql_function_query(MainPipeline, string, false, "OnQueryFinish", "i", SENDDATA_THREAD);

	ATM_Reload(index);

	printf("[ATM System] ATM #%d data updated successfully", index);
	return 1;
}

stock ATM_Reload(index)
{
	new
		string[256];

	if(IsValidDynamicPickup(AtmInfo[index][PickupID]))
		DestroyDynamicPickup(AtmInfo[index][PickupID]);

	if(AtmInfo[index][ObjectHealth] > 0.0 && AtmInfo[index][RobTime] == 0)
		format(string, sizeof(string), "{99D6FF}ATM #%d\n{FFFFFF}Money Availalbe: {33AA33}$%s{FFFFFF}\n\n\
		Press '{FFFF66}Y{FFFFFF}' to use ATM", index, number_format(AtmInfo[index][Money]));
	else if(AtmInfo[index][ObjectHealth] <= 0.0 && AtmInfo[index][RobTime] > 0)
		format(string, sizeof(string), "{AA3333}ATM Broken");

	if(IsValidDynamic3DTextLabel(AtmInfo[index][TextID]))
		UpdateDynamic3DTextLabelText(AtmInfo[index][TextID], COLOR_WHITE, string);
	else
		AtmInfo[index][TextID] = CreateDynamic3DTextLabel(string, COLOR_WHITE, AtmInfo[index][Pos_X], AtmInfo[index][Pos_Y], AtmInfo[index][Pos_Z] + 0.5,
			10.0, .testlos = 0, .worldid = 0, .streamdistance = 10.0);

	if(IsValidDynamicObject(AtmInfo[index][ObjectID]))
	{
		if(IsValidDynamic3DTextLabel(AtmInfo[index][TextID]))
		{
			if(AtmInfo[index][ObjectHealth] > 0.0 && AtmInfo[index][RobTime] == 0)
				Streamer_SetIntData(STREAMER_TYPE_OBJECT, AtmInfo[index][ObjectID], E_STREAMER_MODEL_ID, 19324);
			else if(AtmInfo[index][ObjectHealth] <= 0.0 && AtmInfo[index][RobTime] > 0)
				Streamer_SetIntData(STREAMER_TYPE_OBJECT, AtmInfo[index][ObjectID], E_STREAMER_MODEL_ID, 2943);
		}
	}
	else
	{
		if(AtmInfo[index][ObjectHealth] > 0.0)
			AtmInfo[index][ObjectID] = CreateDynamicObject(19324, AtmInfo[index][Pos_X], AtmInfo[index][Pos_Y], AtmInfo[index][Pos_Z],
				AtmInfo[index][Rot_X], AtmInfo[index][Rot_Y], AtmInfo[index][Rot_Z], .streamdistance = 300.00);
		else if(AtmInfo[index][ObjectHealth] <= 0.0)
			AtmInfo[index][ObjectID] = CreateDynamicObject(2943, AtmInfo[index][Pos_X], AtmInfo[index][Pos_Y], AtmInfo[index][Pos_Z],
				AtmInfo[index][Rot_X], AtmInfo[index][Rot_Y], AtmInfo[index][Rot_Z], .streamdistance = 300.00);
	}
	return 1;
}

stock ATM_AddDefault(playerid)
{
	new
		Float:Pos[3],
		atmid = GetFreeATM();

	GetPlayerPos(playerid, Pos[0], Pos[1], Pos[2]);

	if(atmid == -1)
		return SCM(playerid, COLOR_GREY, "There is no free ATM slot to create");

	AtmInfo[atmid][ID] = atmid;
	AtmInfo[atmid][VirtualWorld] = 0;
	AtmInfo[atmid][Exists] = true;
	AtmInfo[atmid][Pos_X] = Pos[0];
	AtmInfo[atmid][Pos_Y] = Pos[1];
	AtmInfo[atmid][Pos_Z] = Pos[2];
	AtmInfo[atmid][ObjectHealth] = 300.0;
	AtmInfo[atmid][Money] = 50000;
	AtmInfo[atmid][RobTime] = 0;

	ATM_Reload(atmid);
	return atmid;
}

stock ATM_Add(index)
{
	new
		string[2048];

	format(string, sizeof(string), "INSERT INTO `atms` (\
		`ID`, \
		`VirtualWorld`, \
		`Pos_X`, \
		`Pos_Y`, \
		`Pos_Z`, \
		`Rot_X`, \
		`Rot_Y`, \
		`Rot_Z`, \
		`ObjectHealth`, \
		`Money`, \
		`CoolDownTime`) \
		VALUES('%d', '%d', '%f', '%f', '%f', '%f', '%f', '%f', '%f', '%d', '%d')",
		AtmInfo[index][ID],
		AtmInfo[index][VirtualWorld],
		AtmInfo[index][Pos_X],
		AtmInfo[index][Pos_Y],
		AtmInfo[index][Pos_Z],
		AtmInfo[index][Rot_X],
		AtmInfo[index][Rot_Y],
		AtmInfo[index][Rot_Z],
		AtmInfo[index][ObjectHealth],
		AtmInfo[index][Money],
		AtmInfo[index][RobTime]
	);

	mysql_function_query(MainPipeline, string, false, "OnCreateAtmFinish", "iii", -1, index, SENDDATA_ATM);

	printf("[ATM System] ATM #%d created successfully", index);
	return 1;
}

stock ATM_Clear(index)
{
	AtmInfo[index][VirtualWorld] = -1;
	AtmInfo[index][Pos_X] = 0.0;
	AtmInfo[index][Pos_Y] = 0.0;
	AtmInfo[index][Pos_Z] = 0.0;
	AtmInfo[index][Rot_X] = 0.0;
	AtmInfo[index][Rot_Y] = 0.0;
	AtmInfo[index][Rot_Z] = 0.0;
	AtmInfo[index][ObjectHealth] = 0.0;
	AtmInfo[index][Money] = 0;
	AtmInfo[index][RobTime] = 0;

	ATM_Delete(index);
	ATM_Reload(index);
	return 1;
}

stock ATM_Delete(index)
{
	if(AtmInfo[index][Exists])
	{
		new
			string[64];

		format(string, sizeof(string), "DELETE FROM `atms` WHERE  `ID` = '%d'", AtmInfo[index][ID]);

		mysql_function_query(MainPipeline, string, false, "OnQueryFinish", "i", SENDDATA_THREAD);

		ATM_Remove(index);
	}
	return 1;
}

stock ATM_Remove(index)
{
	AtmInfo[index][Exists] = false;

	if(IsValidDynamicObject(AtmInfo[index][ObjectID]))
		DestroyDynamicObject(AtmInfo[index][ObjectID]);

	if(IsValidDynamic3DTextLabel(AtmInfo[index][TextID]))
		DestroyDynamic3DTextLabel(AtmInfo[index][TextID]);

	AtmInfo[index][VirtualWorld] = -1;
	AtmInfo[index][Pos_X] = 0.0;
	AtmInfo[index][Pos_Y] = 0.0;
	AtmInfo[index][Pos_Z] = 0.0;
	AtmInfo[index][Rot_X] = 0.0;
	AtmInfo[index][Rot_Y] = 0.0;
	AtmInfo[index][Rot_Z] = 0.0;
	AtmInfo[index][ObjectHealth] = 0.0;
	AtmInfo[index][Money] = 0;
	AtmInfo[index][RobTime] = 0;

	printf("[ATM System] Deleted successfully ATM #%d", index);
	return 1;
}

stock SetBankPassword(playerid, password[])
{
    new
        hashed_password[65];

    SHA256_PassHash(password, BANK_HASH, hashed_password, MAX_HASH_LENGTH);
    SCMf(playerid, COLOR_GREY, "%s", password);

    format(PlayerInfo[playerid][pMatKhauNganHang], MAX_HASH_LENGTH, "%s", hashed_password);
    return 1;
}

stock VerifyPlayerBankAccountPassword(playerid, password[])
{
    new
        hashed_password[65];

    SHA256_PassHash(password, BANK_HASH, hashed_password, MAX_HASH_LENGTH);

    if(CompareStrings(hashed_password, PlayerInfo[playerid][pMatKhauNganHang]))
        return 1;
    return 0;
}

hook OnPlayerKeyStateChange(playerid, KEY:newkeys, KEY:oldkeys)
{
	new
		string[512],
		i = IsPlayerNearATM(playerid);

	if(PRESSED(KEY_YES) && i != -1)
	{
		if(AtmInfo[i][ObjectHealth] <= 0.0 && AtmInfo[i][RobTime] > 0)
			return SCM(playerid, COLOR_LIGHTRED, "* This ATM has been broken, you can't use it now");

		if(PlayerInfo[playerid][pSoTaiKhoan] == 0)
			return SCM(playerid, COLOR_GREY, "You don't have a bank account to use ATM");

		format(string, sizeof(string), "{FFFFFF}Account: {19AE61}%s {525252}(%d)\n\n\
			{FFFFFF}[{FF0000}!{FFFFFF}] Please enter the password to log in:",
			PlayerInfo[playerid][pTenTaiKhoanNganHang], PlayerInfo[playerid][pSoTaiKhoan]);

		Dialog_Show(playerid, DIALOG_ATM_LOGIN, DIALOG_STYLE_PASSWORD, "ATM > LOGIN MENU", string, ">", "Cancel");
	}
	return 1;
}

hook OnPlayerEditDynamicObject(playerid, objectid, response, Float:x, Float:y, Float:z, Float:rx, Float:ry, Float:rz)
{
	new
		i;

	if((i = GetPVarInt(playerid, #EditATM)) != 0)
	{
		i--;
		
		if(AtmInfo[i][ObjectID] == objectid)
		{
			switch(response)
			{
				case EDIT_RESPONSE_FINAL:
				{
					AtmInfo[i][Pos_X] = x;
                    AtmInfo[i][Pos_Y] = y;
                    AtmInfo[i][Pos_Z] = z;
                    AtmInfo[i][Rot_X] = rx;
                    AtmInfo[i][Rot_Y] = ry;
                    AtmInfo[i][Rot_Z] = rz;

                    SetDynamicObjectPos(AtmInfo[i][ObjectID], AtmInfo[i][Pos_X], AtmInfo[i][Pos_Y], AtmInfo[i][Pos_Z]);
                    SetDynamicObjectRot(AtmInfo[i][ObjectID], AtmInfo[i][Rot_X], AtmInfo[i][Rot_Y], AtmInfo[i][Rot_Y]);

                    SCMf(playerid, COLOR_LIGHTBLUE, "* You have successfully edited ATM #%d object position", i);

                    DeletePVar(playerid, #EditATM);

                    ATM_Update(i);
                }
                case EDIT_RESPONSE_CANCEL:
                {
                	SetDynamicObjectPos(AtmInfo[i][ObjectID], AtmInfo[i][Pos_X], AtmInfo[i][Pos_Y], AtmInfo[i][Pos_Z]);
                    SetDynamicObjectRot(AtmInfo[i][ObjectID], AtmInfo[i][Rot_X], AtmInfo[i][Rot_Y], AtmInfo[i][Rot_Y]);

                    DeletePVar(playerid, #EditATM);
                }
            }
        }
    }
	return 1;
}

Dialog:DIALOG_ATM_LOGIN(playerid, response, listitem, inputtext[])
{
	new
		string[512];

	if(!response)
		return 1;

	if(!VerifyPlayerBankAccountPassword(playerid, inputtext))
	{
		format(string, sizeof(string), "{AA3333}Password is incorrect, please try again\n\n\
			{FFFFFF}Account: {19AE61}%s {525252}(%d)\n\n\
			{FFFFFF}[{FF0000}!{FFFFFF}] Please enter the password to log in:",
			PlayerInfo[playerid][pTenTaiKhoanNganHang], PlayerInfo[playerid][pSoTaiKhoan]);

		Dialog_Show(playerid, DIALOG_ATM_LOGIN, DIALOG_STYLE_PASSWORD, "ATM > LOGIN MENU", string, ">", "Cancel");
		return 1;
	}

	format(string, sizeof(string), "You have successfully loged into bank account %s (%d)",
		PlayerInfo[playerid][pTenTaiKhoanNganHang], PlayerInfo[playerid][pSoTaiKhoan]);

	notification.Show(playerid, "ATM", string, "hud:radar_light");

	format(string, sizeof(string), "{FFFFFF}Account:\t{19AE61}%s {525252}(%d)\n\
		{FFFFFF}Current:\t{33AA33}$%s\n\
		{FFFFFF}-----------------------\n\
		{FF8000}>{FFFFFF} Deposit\n\
		{FF8000}>{FFFFFF} Withdraw",
		PlayerInfo[playerid][pTenTaiKhoanNganHang], PlayerInfo[playerid][pSoTaiKhoan], number_format(PlayerInfo[playerid][pAccount]));

	Dialog_Show(playerid, DIALOG_ATM_MAIN, DIALOG_STYLE_TABLIST, "ATM > MAIN MENU", string, "Choose", "Cancel");
	return 1;
}

Dialog:DIALOG_ATM_MAIN(playerid, response, listitem, inputtext[])
{
	new
		string[256];

	if(!response)
		return 1;

	switch(listitem)
	{
		case 3:
		{
			format(string, sizeof(string), "{FFFFFF}Account: {19AE61}%s {525252}(%d)\n\
				{FFFFFF}Current: {33AA33}$%s\n\
				{FFFFFF}Money: {33AA33}$%s\n\n\
				{FFFFFF}[{FF0000}!{FFFFFF}] Please enter the amount of money you want to deposit:",
				PlayerInfo[playerid][pTenTaiKhoanNganHang], PlayerInfo[playerid][pSoTaiKhoan],
				number_format(PlayerInfo[playerid][pAccount]),
				number_format(PlayerInfo[playerid][pCash]));

			Dialog_Show(playerid, DIALOG_ATM_DEPOSIT, DIALOG_STYLE_INPUT, "ATM > DEPOSIT", string, ">", "Cancel");
		}
		case 4:
		{
			format(string, sizeof(string), "{FFFFFF}Account: {19AE61}%s {525252}(%d)\n\
				{FFFFFF}Current: {33AA33}$%s\n\n\
				{FFFFFF}[{FF0000}!{FFFFFF}] Please enter the amount of money you want to withdraw:",
				PlayerInfo[playerid][pTenTaiKhoanNganHang], PlayerInfo[playerid][pSoTaiKhoan],
				number_format(PlayerInfo[playerid][pAccount]));

			Dialog_Show(playerid, DIALOG_ATM_WITHDRAW, DIALOG_STYLE_INPUT, "ATM > WITHDRAW", string, ">", "Cancel");
		}
	}
	return 1;
}

Dialog:DIALOG_ATM_DEPOSIT(playerid, response, listitem, inputtext[])
{
	new
		current = PlayerInfo[playerid][pAccount],
		string[256],
		i = IsPlayerNearATM(playerid);

	if(!response)
		return 1;

	if(!IsNumeric(inputtext) || strval(inputtext) < 1)
	{
		format(string, sizeof(string), "{AA3333}The amount of money you entered was invalid, please try again\n\n\
			{FFFFFF}Account: {19AE61}%s {525252}(%d)\n\
				{FFFFFF}Current: {33AA33}$%s\n\
				{FFFFFF}Money: {33AA33}$%s\n\n\
				{FFFFFF}[{FF0000}!{FFFFFF}] Pleae enter the amount of money you want to deposit:",
				PlayerInfo[playerid][pTenTaiKhoanNganHang], PlayerInfo[playerid][pSoTaiKhoan],
				number_format(PlayerInfo[playerid][pAccount]),
				number_format(PlayerInfo[playerid][pCash]));

		Dialog_Show(playerid, DIALOG_ATM_DEPOSIT, DIALOG_STYLE_INPUT, "ATM > DEPOSIT", string, ">", "Cancel");
		return 1;
	}

	if(PlayerInfo[playerid][pCash] < strval(inputtext))
		return SCM(playerid, COLOR_GREY, "You don't have enough money that you have entered to deposit");

	if(gettime() - GetPVarInt(playerid, "LastTransaction") < 10)
		return SCM(playerid, COLOR_GREY, "Please wait 10 seconds before making a new transaction");

	SetPVarInt(playerid, "LastTransaction", gettime());

	if(strval(inputtext) > 500)
	{
		PlayerInfo[playerid][pCash] -= strval(inputtext);
		PlayerInfo[playerid][pAccount] += strval(inputtext) * ATM_FEE / 100;
		AtmInfo[i][Money] += strval(inputtext) * ATM_FEE / 100;

		ATM_Update(i);

		SCM(playerid, COLOR_GREY, "|___ BANK STATEMENT ___|");
		SCMf(playerid, COLOR_GREY, " Old Balance: {33AA33}$%s", number_format(current));
		SCMf(playerid, COLOR_GREY, " Deposit: {33AA33}$%s", number_format(strval(inputtext)));
		SCMf(playerid, COLOR_GREY, " Transaction Fee: {33AA33}$%s", number_format(strval(inputtext) * 20 / 100));
		SCM(playerid, COLOR_GREY, "|-----------------------------------------|");
		SCMf(playerid, COLOR_GREY, " New Balance: {33AA33}$%s", number_format(PlayerInfo[playerid][pAccount]));

		format(string, sizeof(string), "%s (IP: %s) has deposited $%s (Transaction Fee: $%s) into account %s (%d)",
			GetPlayerNameEx(playerid), GetPlayerIpEx(playerid), number_format(strval(inputtext)), number_format(strval(inputtext) * 20 / 100),
			PlayerInfo[playerid][pTenTaiKhoanNganHang], PlayerInfo[playerid][pSoTaiKhoan]);

		Log("Logs/Player/AtmDeposit.log", string);
		
		OnPlayerStatsUpdate(playerid);
	}
	else
	{
		PlayerInfo[playerid][pCash] -= strval(inputtext);
		PlayerInfo[playerid][pAccount] += strval(inputtext);
		AtmInfo[i][Money] += strval(inputtext);

		ATM_Update(i);

		SCM(playerid, COLOR_GREY, "|___ BANK STATEMENT ___|");
		SCMf(playerid, COLOR_GREY, " Old Balance: {33AA33}$%s", number_format(current));
		SCMf(playerid, COLOR_GREY, " Deposit: {33AA33}$%s", number_format(strval(inputtext)));
		SCMf(playerid, COLOR_GREY, " Transaction Fee: {33AA33}$0");
		SCM(playerid, COLOR_GREY, "|-----------------------------------------|");
		SCMf(playerid, COLOR_GREY, " New Balance: {33AA33}$%s", number_format(PlayerInfo[playerid][pAccount]));

		format(string, sizeof(string), "%s (IP: %s) has deposited $%s (Transaction Fee: $0) into account %s (%d)",
			GetPlayerNameEx(playerid), GetPlayerIpEx(playerid), number_format(strval(inputtext)),
			PlayerInfo[playerid][pTenTaiKhoanNganHang], PlayerInfo[playerid][pSoTaiKhoan]);

		Log("Logs/Player/AtmDeposit.log", string);
		
		OnPlayerStatsUpdate(playerid);
	}
	return 1;
}

Dialog:DIALOG_ATM_WITHDRAW(playerid, response, listitem, inputtext[])
{
	new
		current = PlayerInfo[playerid][pAccount],
		string[256],
		i = IsPlayerNearATM(playerid);

	if(!response)
		return 1;

	if(!IsNumeric(inputtext) || strval(inputtext) < 1)
	{
		format(string, sizeof(string), "{AA3333}The amount of money you entered was invalid, please try again\n\n\
			{FFFFFF}Account: {19AE61}%s {525252}(%d)\n\
				{FFFFFF}Current: {33AA33}$%s\n\n\
				{FFFFFF}[{FF0000}!{FFFFFF}] Please enter the amount of money you want to withdraw:",
				PlayerInfo[playerid][pTenTaiKhoanNganHang], PlayerInfo[playerid][pSoTaiKhoan],
				number_format(PlayerInfo[playerid][pAccount]));

		Dialog_Show(playerid, DIALOG_ATM_WITHDRAW, DIALOG_STYLE_INPUT, "ATM > WITHDRAW", string, ">", "Cancel");
		return 1;
	}

	if(PlayerInfo[playerid][pAccount] < strval(inputtext))
		return SCM(playerid, COLOR_GREY, "You don't have enough money that you have entered to withdraw");

	if(gettime() - GetPVarInt(playerid, "LastTransaction") < 10)
		return SCM(playerid, COLOR_GREY, "Please wait 10 seconds before making a new transaction");

	if(AtmInfo[i][Money] < strval(inputtext))
		return SCM(playerid, COLOR_GREY, "This ATM doesn't have enough money that you have entered to withdraw");

	SetPVarInt(playerid, "LastTransaction", gettime());

	if(strval(inputtext) > 500)
	{
		PlayerInfo[playerid][pCash] += strval(inputtext) * ATM_FEE / 100;
		PlayerInfo[playerid][pAccount] -= strval(inputtext);
		AtmInfo[i][Money] -= strval(inputtext);

		ATM_Update(i);

		SCM(playerid, COLOR_GREY, "|___ BANK STATEMENT ___|");
		SCMf(playerid, COLOR_GREY, " Old Balance: {33AA33}$%s", number_format(current));
		SCMf(playerid, COLOR_GREY, " Withdraw: {33AA33}$%s", number_format(strval(inputtext)));
		SCMf(playerid, COLOR_GREY, " Transaction Fee: {33AA33}$%s", number_format(strval(inputtext) * 20 / 100));
		SCM(playerid, COLOR_GREY, "|-----------------------------------------|");
		SCMf(playerid, COLOR_GREY, " New Balance: {33AA33}$%s", number_format(PlayerInfo[playerid][pAccount]));

		format(string, sizeof(string), "%s (IP: %s) has withdrew $%s (Transaction Fee: $%s) from account %s (%d)",
			GetPlayerNameEx(playerid), GetPlayerIpEx(playerid), number_format(strval(inputtext)), number_format(strval(inputtext) * 20 / 100),
			PlayerInfo[playerid][pTenTaiKhoanNganHang], PlayerInfo[playerid][pSoTaiKhoan]);

		Log("Logs/Player/AtmWithdraw.log", string);
		
		OnPlayerStatsUpdate(playerid);
	}
	else
	{
		PlayerInfo[playerid][pCash] += strval(inputtext);
		PlayerInfo[playerid][pAccount] -= strval(inputtext);
		AtmInfo[i][Money] -= strval(inputtext);

		ATM_Update(i);

		SCM(playerid, COLOR_GREY, "|___ BANK STATEMENT ___|");
		SCMf(playerid, COLOR_GREY, " Old Balance: {33AA33}$%s", number_format(current));
		SCMf(playerid, COLOR_GREY, " Withdraw: {33AA33}$%s", number_format(strval(inputtext)));
		SCMf(playerid, COLOR_GREY, " Transaction Fee: {33AA33}$0");
		SCM(playerid, COLOR_GREY, "|-----------------------------------------|");
		SCMf(playerid, COLOR_GREY, " New Balance: {33AA33}$%s", number_format(PlayerInfo[playerid][pAccount]));

		format(string, sizeof(string), "%s (IP: %s) has withdrew $%s (Transaction Fee: $0) from account %s (%d)",
			GetPlayerNameEx(playerid), GetPlayerIpEx(playerid), number_format(strval(inputtext)),
			PlayerInfo[playerid][pTenTaiKhoanNganHang], PlayerInfo[playerid][pSoTaiKhoan]);

		Log("Logs/Player/AtmWithdraw.log", string);
		
		OnPlayerStatsUpdate(playerid);
	}
	return 1;
}

CMD:aatm(playerid, params[])
{
	new
		choice[32],
		string[256],
		atmid;

	if(PlayerInfo[playerid][pAdmin] < 1338)
		return SendNotAdmin(playerid);

	if(Aduty[playerid] == 0)
		return SendNotDutyAdmin(playerid);

	if(sscanf(params, "s[32]D(-1)", choice, atmid))
	{
		SDM(playerid, "/aatm [Option] [Atm ID]");
		SCM(playerid, COLOR_GREY, "OPTION: create / delete / goto / object");
		return 1;
	}

	if(strcmp(choice, "create", true) == 0)
	{
		atmid = ATM_AddDefault(playerid);

		SCMf(playerid, COLOR_LIGHTBLUE, "* You have successfully created ATM #%d", atmid);

		ATM_Add(atmid);
	}
	else if(strcmp(choice, "delete", true) == 0)
	{
		if(AtmInfo[atmid][Exists] == false)
			return SCM(playerid, COLOR_GREY, "ATM ID is invalid, please try again");

		ATM_Clear(atmid);
		ATM_Update(atmid);

		SCMf(playerid, COLOR_LIGHTBLUE, "* You have successfully deleted ATM #%d", atmid);
	}
	else if(strcmp(choice, "goto", true) == 0)
	{
		if(AtmInfo[atmid][Exists] == false)
			return SCM(playerid, COLOR_GREY, "ATM ID is invalid, please try again");

		if(AtmInfo[atmid][Pos_X] == 0.0)
			return 1;

		format(string, sizeof(string), "~w~You have successfully teleported to ~y~ATM #%d", atmid);

		SetPlayerInterior(playerid, 0);
		SetPlayerVirtualWorld(playerid, 0);

		PlayerInfo[playerid][pInt] = 0;
		PlayerInfo[playerid][pVW] = 0;

		SetPlayerPos(playerid, AtmInfo[atmid][Pos_X], AtmInfo[atmid][Pos_Y], AtmInfo[atmid][Pos_Z]);
	}
	else if(strcmp(choice, "object", true) == 0)
	{
		if(AtmInfo[atmid][Exists] == false)
			return SCM(playerid, COLOR_GREY, "ATM ID is invalid, please try again");

		if(AtmInfo[atmid][ObjectID] == INVALID_OBJECT_ID)
			return 1;

		EditDynamicObject(playerid, AtmInfo[atmid][ObjectID]);

		SetPVarInt(playerid, #EditATM, atmid + 1);

		SCMf(playerid, COLOR_LIGHTRED, "* You are now editing the object position of ATM #%d", atmid);
	}
	return 1;
}

CMD:setatmobjecthp(playerid, params[])
{
	new
		atmid,
		hp;

	if(PlayerInfo[playerid][pAdmin] < 1338)
		return SendNotAdmin(playerid);

	if(Aduty[playerid] == 0)
		return SendNotDutyAdmin(playerid);

	if(sscanf(params, "dd", atmid, hp))
		return SDM(playerid, "/setatmobjecthp [Atm ID] [Object HP]");

	if(AtmInfo[atmid][Exists] == false)
		return SCM(playerid, COLOR_GREY, "ATM ID is invalid, please try again");

	if(hp > 300 || hp < 0)
		return SCM(playerid, COLOR_GREY, "Object HP is invalid, please try again");

	AtmInfo[atmid][ObjectHealth] = hp;

	ATM_Update(atmid);
	return 1;
}

CMD:setatmrobtime(playerid, params[])
{
	new
		atmid,
		time;

	if(PlayerInfo[playerid][pAdmin] < 1338)
		return SendNotAdmin(playerid);

	if(Aduty[playerid] == 0)
		return SendNotDutyAdmin(playerid);

	if(sscanf(params, "dd", atmid, time))
		return SDM(playerid, "/setatmrobtime [Atm ID] [Time]");

	if(AtmInfo[atmid][Exists] == false)
		return SCM(playerid, COLOR_GREY, "ATM ID is invalid, please try again");

	if(time > 120 || time < 0)
		return SCM(playerid, COLOR_GREY, "Time is invalid, please try again");

	AtmInfo[atmid][RobTime] = time;

	ATM_Update(atmid);
	return 1;
}

// >> MACROS << //

#define SendNotAdmin(%0) \
    SendClientMessage(%0, COLOR_GREY, "You don't have permission to use that command")

#define SendNotDutyAdmin(%0) \
    SendClientMessage(%0, COLOR_GREY, "You are not on Admin Duty to use this command")

#define SDM(%0,%1) \
    SendClientMessage(%0, COLOR_GREY, "USEAGE: "%1)

#define SCMf(%0,%1,%2) \
	SendClientMessageFormated(%0, %1, %2)

	//  >> SendClientMessageFormated is an exclusive function, so if you want to have that please DM me at this link https://facebook.com/nquyenZ.26 << //