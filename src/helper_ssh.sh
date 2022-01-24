#!/bin/bash

# Structure:ssh
# Activates/enables the ssh for 
activate_ssh_account() {
	git_username=$1
	#eval "$(ssh-agent -s)"
	#$(eval "$(ssh-agent -s)")
	#$("$(ssh-agent -s)")
	#$(ssh-add ~/.ssh/"$git_username")
	#ssh-add ~/.ssh/"$git_username"
	eval "$(ssh-agent -s 3>&-)"
    ssh-add ~/.ssh/"$git_username"
}

# Structure:ssh
# Check ssh-access to GitHub repo.
check_ssh_access_to_repo() {
	local local_git_username=$1
	github_repository=$2
	retry=$3
	
	# shellcheck disable=SC2034
	my_service_status=$(git ls-remote git@github.com:"$local_git_username"/"$github_repository".git 2>&1)
	found_error_in_ssh_command=$(lines_contain_string "ERROR" "\${my_service_status}")
	
	if [ "$found_error_in_ssh_command" == "NOTFOUND" ]; then
		echo "HASACCESS"
	elif [ "$found_error_in_ssh_command" == "FOUND" ]; then
		if [ "$retry" == "YES" ]; then
			echo "Your ssh-account:$local_git_username does not have pull access to the repository:$github_repository"
			exit 4
			# TODO: Throw error
			#(A public repository should grant ssh access even if no ssh credentials for that GitHub user is given.)
		else
			#activate_ssh_account "$local_git_username"
			check_ssh_access_to_repo "$local_git_username" "$github_repository" "YES"
		fi
	fi
}

# Structure:ssh
has_access() {
	local github_repo="$1"
	#echo $(check_ssh_access_to_repo "$GITHUB_USERNAME_GLOBAL" "$github_repo")
	check_ssh_access_to_repo "$GITHUB_USERNAME_GLOBAL" "$github_repo"
}


#######################################
# 
# Local variables:
# 
# Globals:
#  None.
# Arguments:
#   
# Returns:
#  0 if 
#  7 if 
# Outputs:
#  None.
# TODO(a-t-0): change root with Global variable.
#######################################
# Structure:Github_status
# Structure:ssh
# Returns FOUND if the incoming ssh account is activated,
# returns NOTFOUND otherwise.
github_account_ssh_key_is_added_to_ssh_agent() {
	local ssh_account="$1"
	local activated_ssh_output=("$@")
	found="false"
	
	
	count=0
	while IFS= read -r line; do
		count=$((count+1))
		
		# Get the username from the ssh key .pub file.
		local username
		username="$(get_last_space_delimted_item_in_line "$line")"
		
		if [ "$username" == "$ssh_account" ]; then
			if [ "$found" == "false" ]; then
				echo "FOUND"
				found="true"
			fi
		fi

	done <<< "${activated_ssh_output[@]}"
	if [ "$found" == "false" ]; then
		echo "NOTFOUND"
	fi
}


#######################################
# 
# Local variables:
# 
# Globals:
#  None.
# Arguments:
#   
# Returns:
#  0 if 
#  7 if 
# Outputs:
#  None.
# TODO(a-t-0): change root with Global variable.
#######################################
# Structure:ssh
# Checks for both GitHub username as well as for the email address that is 
# tied to that acount.
any_ssh_key_is_added_to_ssh_agent() {
	local ssh_account=$1
	local ssh_output
	ssh_output=$(ssh-add -L)
	
	# Check if the ssh key is added to ssh-agent by means of username.
	found_ssh_username="$(github_account_ssh_key_is_added_to_ssh_agent "$ssh_account" "\"${ssh_output}")"
	if [[ "$found_ssh_username" == "FOUND" ]]; then
		echo "FOUND"
	else
		
		# Get the email address tied to the ssh-account.
		ssh_email=$(get_ssh_email "$ssh_account")
		#echo "ssh_email=$ssh_email"
		
		if [ "$ssh_email" == "" ]; then
			#echo "The ssh key file does not exist, so the email address of that ssh-account can not be extracted."
			echo "NOTFOUND_FILE"
			exit 27
		else 
			
			# Check if the ssh key is added to ssh-agent by means of email.
			found_ssh_email="$(github_account_ssh_key_is_added_to_ssh_agent "$ssh_email" "\"${ssh_output}")"
			
			if [ "$found_ssh_email" == "FOUND" ]; then
				echo "FOUND"
			else
				#manual_assert_equal  "$found_ssh_email" "FOUND"
				echo "NOTFOUND_EMAIL"
			fi
		fi
	fi
}


#######################################
# 
# Local variables:
# 
# Globals:
#  None.
# Arguments:
#   
# Returns:
#  0 if 
#  7 if 
# Outputs:
#  None.
# TODO(a-t-0): change root with Global variable.
#######################################
# Structure:ssh
verify_ssh_key_is_added_to_ssh_agent() {
	local ssh_account=$1
	local ssh_output
	ssh_output=$(ssh-add -L)
	local ssh_key_in_ssh_agent
	ssh_key_in_ssh_agent=$(any_ssh_key_is_added_to_ssh_agent "$ssh_account")
	if [[ "$ssh_key_in_ssh_agent" == "NOTFOUND_FILE" ]] || [[ "$ssh_key_in_ssh_agent" == "NOTFOUND_EMAIL" ]]; then
		printf 'Please ensure the ssh-account '%ssh_account' key is added to the ssh agent. You can do that with commands:'"\\n"" eval $(ssh-agent -s)""\n"'ssh-add ~/.ssh/'$ssh_account''"\n"' Please run this script again once you are done.'
		exit 28
	fi
}


#######################################
# 
# Local variables:
# 
# Globals:
#  None.
# Arguments:
#   
# Returns:
#  0 if 
#  7 if 
# Outputs:
#  None.
# TODO(a-t-0): change root with Global variable.
#######################################
# Structure:ssh
# Untested function to retrieve email pertaining to ssh key
get_ssh_email() {
	local ssh_account=$1
	
	local username
	username=$(whoami)
	local key_filepath="/home/$username/.ssh/$ssh_account.pub"
	
	# Check if file exists.
	manual_assert_file_exists "$key_filepath"
	
	# Read the ssh pub file.
	local public_ssh_content
	public_ssh_content=$(cat "$key_filepath")
	
	# Get email from ssh pub file.
	local email
	email=$(get_last_space_delimted_item_in_line "$public_ssh_content")
	echo "$email"
}