# /etc/skel/.bashrc
#
# This file is sourced by all *interactive* bash shells on startup,
# including some apparently interactive shells such as scp and rcp
# that can't tolerate any output.  So make sure this doesn't display
# anything or bad things will happen !


# Test for an interactive shell.  There is no need to set anything
# past this point for scp and rcp, and it's important to refrain from
# outputting anything in those cases.
if [[ $- != *i* ]] ; then
	# Shell is non-interactive.  Be done now!
	return
fi

# Put your fun stuff here.

# save all commands to /usrdata/.bash-history.json
export PROMPT_COMMAND='(';
PROMPT_COMMAND+='EXIT_CODE=$?;';
PROMPT_COMMAND+='if [ "$(id -u)" -ne 0 ]; then ';
PROMPT_COMMAND+='HISTORY_COMMAND=$(HISTTIMEFORMAT="%s " history 1);';
PROMPT_COMMAND+='PARSED_COMMAND=$(echo $HISTORY_COMMAND | cut -d " " -f 3- | jq -M -R ".");';
PROMPT_COMMAND+='if [[ $PARSED_COMMAND != "\"\"" ]]; then ';
PROMPT_COMMAND+='COMMAND_NUMBER=$(echo $HISTORY_COMMAND | cut -d " " -f 1);';
PROMPT_COMMAND+='COMMAND_TIME=$(echo $HISTORY_COMMAND | cut -d " " -f 2);';
PROMPT_COMMAND+='WORKING_DIR=$(pwd | jq -M -R ".");';
PROMPT_COMMAND+='echo "{\"time\":$COMMAND_TIME,\"pwd\":$WORKING_DIR,\"command\":$PARSED_COMMAND,\"exit_code\":$EXIT_CODE,\"command_number\":$COMMAND_NUMBER}" >> /data/$(hostname)-bash-history.json;';
PROMPT_COMMAND+='fi ';
PROMPT_COMMAND+='fi)';
