#!/bin/bash

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
# Structure:Parsing
# Run with:
# bash -c "source src/import.sh && get_repos_from_api_query_json"
get_repos_from_api_query_json() {
	filepath="src/eg_query.json"
	
	json=$(cat $filepath)
	#echo "json=$json"

	# First repo:
	#echo "$(echo "$json" | jq ".[][].repositories[][0]")"
	# Second repo
	#echo "$(echo "$json" | jq ".[][].repositories[][1]")"
	
	echo "$(echo "$json" | jq ".[][].repositories[][55]")"
	exit 4
	readarray -t branch_names_arr <  <(echo "$json" | jq ".[][].repositories") # works
	#readarray -t branch_names_arr <  <(echo "$json" | jq ".[][].repositories[][].nameWithOwner")
	#readarray -t branch_names_arr <  <(echo "$json" | jq ".[][].repositories[][][].nameWithOwner") # Gets first repo
	#readarray -t branch_names_arr <  <(echo "$json" | jq ".[][][][][][].nameWithOwner") # Gets first repo
	
	readarray -t branch_commits_arr <  <(echo "$json" | jq ".[].oid")
	echo "branch_names_arr=${branch_names_arr[@]}"
	echo "branch_commits_arr=${branch_commits_arr[@]}"
	
	# Loop through branches using a mutual index i.
	#for i in "${!branch_names_arr[@]}"; do
	#	echo "${branch_names_arr[i]}" 
	#	echo "i=$i"
	#done

}



# Run with:
# bash -c "source src/import.sh && loop_through_repos_in_api_query_json"
loop_through_repos_in_api_query_json() {
	# Specify max nr of repos in a query response.
	local max_repos=100 
	local max_commits=100
	
	# Load json to variable.
	local filepath="src/eg_query.json"
	local json=$(cat $filepath)
	
	# Remove unneeded json wrapper
	local eaten_wrapper="$(echo "$json" | jq ".[][][][]")"
	
	# Loop 0 to 100 (including 100)
	local i=-1
	while [ $max_repos -ge $i ]
	do
		local i=$(($i+1))
		# Store the output of the json parsing function
		local some_value=$(evaluate_repo "$max_repos" "$(echo "$eaten_wrapper" | jq ".[$i]")")
		local repo_cursor=$(get_repo_cursor "$max_repos" "$(echo "$eaten_wrapper" | jq ".[$i]")")
		local repo_name=$(get_repo_name "$max_repos" "$(echo "$eaten_wrapper" | jq ".[$i]")")

		# Loop through commits
		local commits=$(loop_through_commits_in_repo_json "$max_commits" "$(echo "$eaten_wrapper" | jq ".[$i]")")
		echo "commits=$commits"

		# Determine whether the entry was null or not.
		evaluate_repo "$max_repos" "$(echo "$eaten_wrapper" | jq ".[$i]")"
		local res=$? # Get the return value of the function.
		echo "i=$i, repo_cursor=$repo_cursor"
		echo "i=$i, repo_name=$repo_name"

		# Check if the JSON contained null or if the next entry may still 
		# contain repository data.
		if [ $i -ge $res ]; then
			# Ensure while loop is broken numerically.
			local i=$(( $max_repos + $max_repos ))
		fi
	done
}

evaluate_repo() {
	local max_repos="$1"
	local repo_json="$2"
	if [ "$repo_json" == "null" ]; then
		return $max_repos
	else
		return 1
	fi
}

get_repo_cursor() {
	local max_repos="$1"
	local repo_json="$2"
	#echo "repo_json=$repo_json"
	if [ "$repo_json" == "null" ]; then
		return $max_repos
	else
		echo "$(echo "$repo_json" | jq ".cursor")"
		return 1
	fi
}

get_repo_name() {
	local max_repos="$1"
	local repo_json="$2"
	if [ "$repo_json" == "null" ]; then
		return $max_repos
	else
		echo "$(echo "$repo_json" | jq ".node.name")"
		return 1
	fi
}

loop_through_commits_in_repo_json() {
	local max_commits="$1"
	local commits_json="$2"
	
	# Remove unneeded json wrapper
	local eaten_wrapper="$(echo "$commits_json" | jq ".node")"
	echo "eaten_wrapper=$eaten_wrapper"
	# Loop 0 to 100 (including 100)
	local i=-1
	#while [ $max_repos -ge $i ]
	#do
	#	local i=$(($i+1))
	#	# Store the output of the json parsing function
	#	local some_value=$(evaluate_repo "$max_repos" "$(echo "$eaten_wrapper" | jq ".[$i]")")
	#	#local repo_cursor=$(get_repo_cursor "$max_repos" "$(echo "$eaten_wrapper" | jq ".[$i]")")
	#	#local repo_name=$(get_repo_name "$max_repos" "$(echo "$eaten_wrapper" | jq ".[$i]")")
#
	#	# Determine whether the entry was null or not.
	#	evaluate_commit "$max_repos" "$(echo "$eaten_wrapper" | jq ".[$i]")"
	#	local res=$? # Get the return value of the function.
	#	#echo "i=$i, repo_cursor=$repo_cursor"
	#	#echo "i=$i, repo_name=$repo_name"
#
	#	# Check if the JSON contained null or if the next entry may still 
	#	# contain repository data.
	#	if [ $i -ge $res ]; then
	#		# Ensure while loop is broken numerically.
	#		local i=$(( $max_repos + $max_repos ))
	#	fi
	#done

}