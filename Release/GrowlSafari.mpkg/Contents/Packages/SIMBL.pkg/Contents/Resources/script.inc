# $Header: /Users/msolomon/Developer/cvs/SIMBL/simbl-resources/script.inc,v 1.1 2003/07/10 06:15:57 msolomon Exp $

# $1 an absolute path to a  directory to create/repermission
# chown to root:admin, chmod to 775
function ensure_root_admin_directory()
{
	local DIRECTORY="$1"
	
	echo "script: $0"
	id
	echo "pwd: $(pwd)"

	if [ ! -e "${DIRECTORY}" ]; then 
		mkdir -m g+rwx -p "${DIRECTORY}"
		if [ $? -ne 0 ]; then
			echo "failed to create ${DIRECTORY}"
			return 1
		fi
	fi 

	ls -ld "${DIRECTORY}"

	chown :admin "${DIRECTORY}"
	if [ $? -ne 0 ]; then
		echo "failed to chown ${DIRECTORY}"
		return 2
	fi

	ls -ld "${DIRECTORY}"

	chmod 775 "${DIRECTORY}"
	if [ $? -ne 0 ]; then
		echo "failed to chmod ${DIRECTORY}"
		return 3
	fi

	ls -ld "${DIRECTORY}"
	return 0
}

