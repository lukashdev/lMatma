#include <sourcemod>
#include <multicolors>
#include <store>

#pragma tabsize 0
#pragma newdecls required
#pragma semicolon 1

#define TAG "{lightred}Matma"

#define PLUGIN_AUTHOR "lukash"
#define PLUGIN_VERSION "1.0.1"
#define PLUGIN_NAME "lMatma"
#define PLUGIN_DESCRIPTION "System automatycznych działań matematycznych za kredyty"
#define PLUGIN_URL "https://steamcommunity.com/id/lukasz11772/"

public Plugin myinfo = 
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

Handle cv_minNumber;
Handle cv_maxNumber;
Handle cv_minNumber2;
Handle cv_maxNumber2;
Handle cv_minReward;
Handle cv_maxReward;
Handle cv_TimeQuestion;
Handle cv_TimeAnswer;
Handle timerEndQuestion;

bool isMath = false;

char op[128];
char operators[4][2] = {"+", "-", ":", "x"};

int Answer;
int Reward;

public void OnPluginStart()
{
    cv_minNumber = CreateConVar("sm_minNumber", "10", "Minimalna liczba w działaniu (dodawanie/odejmowanie)");
    cv_maxNumber = CreateConVar("sm_maxNumber", "100", "Maksymalna liczba w działaniu (dodawanie/odejmowanie)");
    cv_minNumber2 = CreateConVar("sm_minNumber2", "5", "Minimalna liczba w działaniu (mnożenie/dzielenie)");
    cv_maxNumber2 = CreateConVar("sm_maxNumber2", "20", "Maksymalna liczba w działaniu (mnożenie/dzielenie)");
    cv_minReward = CreateConVar("sm_minReward", "10", "Minimalna nagroda");
    cv_maxReward = CreateConVar("sm_maxReward", "70", "Maksymalna nagroda");
    cv_TimeQuestion = CreateConVar("sm_TimeQuestion", "60", "Czas pomiędzy pytaniami");
    cv_TimeAnswer = CreateConVar("sm_TimeAnswer", "15", "Czas na odpowiedź");

    AddCommandListener(Say, "say");
	AddCommandListener(Say,  "say_team");

    AutoExecConfig(true, "lMatma");
}

public void OnMapStart()
{
    CreateTimer(GetConVarFloat(cv_TimeQuestion)+GetConVarFloat(cv_TimeAnswer), Pytanie, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action Pytanie(Handle timer)
{
    int Number1, Number2;
    Reward = GetRandomInt(GetConVarInt(cv_minReward), GetConVarInt(cv_maxReward));
    Format(op, sizeof(op), operators[GetRandomInt(0, 3)]);
    if(StrEqual(op, "+") || StrEqual(op, "-"))
    {
        if(StrEqual(op, "+"))
        {
            Number1 = GetRandomInt(GetConVarInt(cv_minNumber), GetConVarInt(cv_maxNumber));
            Number2 = GetRandomInt(GetConVarInt(cv_minNumber), GetConVarInt(cv_maxNumber));
            Answer = Number1 + Number2;
        }
        else if(StrEqual(op, "-"))
        {
            Number1 = GetRandomInt(GetConVarInt(cv_minNumber), GetConVarInt(cv_maxNumber));
            Number2 = GetRandomInt(GetConVarInt(cv_minNumber), GetConVarInt(cv_maxNumber));
            Answer = Number1 - Number2;
        }
    }
    else if(StrEqual(op, "x") || StrEqual(op, ":"))
    {
        if(StrEqual(op, "x"))
        {
            Number1 = GetRandomInt(GetConVarInt(cv_minNumber2), GetConVarInt(cv_maxNumber2));
            Number2 = GetRandomInt(GetConVarInt(cv_minNumber2), GetConVarInt(cv_maxNumber2));
            Answer = Number1 * Number2;
        }
        else if(StrEqual(op, ":"))
        {
            int tempnumber;
            Number1 = GetRandomInt(GetConVarInt(cv_minNumber2), GetConVarInt(cv_maxNumber2));
            Number2 = GetRandomInt(GetConVarInt(cv_minNumber2), GetConVarInt(cv_maxNumber2));
            if(Number1 < Number2)
            {
                tempnumber = Number2;
                Number2 = Number1;
                Number1 = tempnumber;

            }
            Answer = Number1*3 / Number2;
        }
    }

    isMath = true;
    CPrintToChatAll("%s {darkred}>>{default} Wykonaj działanie {darkred}> {lightred}%i %s %i{default}. Nagrodą jest {lightred}%i{default} kredytów", TAG, Number1, op, Number2, Reward);

    timerEndQuestion = CreateTimer(GetConVarFloat(cv_TimeAnswer), EndQuestion);
}

public Action EndQuestion(Handle timer)
{
    EndQuestionAnswer(-1);
}

public Action Say(int client, const char[] command, int args)
{
    char arg[128];

    if(!isMath)
        return;

    if(!IsValidClient(client))
        return;
    
    GetCmdArgString(arg, sizeof(arg));
    StripQuotes(arg);

    char sAnswer[128];
    IntToString(Answer, sAnswer, sizeof(sAnswer));

    if(StrEqual(arg, sAnswer))
    {
        Store_SetClientCredits(client, Store_GetClientCredits(client) + Reward);
        EndQuestionAnswer(client);
    }
}

public void EndQuestionAnswer(int client)
{
    if(timerEndQuestion != INVALID_HANDLE)
	{
		KillTimer(timerEndQuestion);
		timerEndQuestion = INVALID_HANDLE;
	}
    if(client == -1)
        CPrintToChatAll("%s {darkred}>>{default} Nikt nie podał poprawnej odpowiedzi!", TAG);
    else
        CPrintToChatAll("%s {darkred}>> {lightred}%N {default}podał poprawny wynik. Wygrał {lightred}%i {default}kredytów!", TAG, client, Reward);
    isMath = false;
}

stock bool IsValidClient (int iClient, bool bReplay = true)
{
	if (iClient <= 0 || iClient > MaxClients)
		return false;
	if (!IsClientInGame(iClient))
		return false;
	if (bReplay && (IsClientSourceTV(iClient) || IsClientReplay(iClient)))
		return false;
	return true;
}