#!/bin/bash
WHICH_PYTHON=$(which python > /dev/null 2>&1)
if [ $? == 1 ]; then echo "Python was not detected. Exiting."; exit 1; fi;

# Define the help function
# -h flag
function show_help {
	# TODO: Make this run python insights-client.egg --help
	echo "Usage: insights-client [options]"
	echo ""
	echo "Options:"
	echo -e "-h\t HALP!"
	echo -e "-v\t Get the version."
	echo -e "-V\t Verbose output."
	echo -e "-d\t Run in development mode, this uses the local egg source instead of reaching out to the mothership."
	echo -e "-g\t Retrieve the Egg from the Git repo https://github.com/RedHatInsights/insights-client instead of Red Hat mothership."
	echo -e "-G\t Run with no GPG verficiation."
	exit 0;
}

# Define the version function
# -v flag
function show_version {
	# TODO: Make this run python insights-client.egg --version
	echo "Insights Client Version X.X.X"
	exit 0;
}

# Setup flags & placeholders
OPTIND=1
DEVMODE=0
USEGIT=0
NOGPG=0
VERBOSE=0
DONTBUILD=0
# TODO: Make this support --verbose, --help, --etc long flags
while getopts "dhvVgGb" opt; do
	case "$opt" in
	h) show_help ;;
	v) show_version ;;
	d) DEVMODE=1 ;;
	g) USEGIT=1 ;;
	G) NOGPG=1 ;;
	V) VERBOSE=1 ;;
	b) DONTBUILD=1 ;;
	esac
done
shift $((OPTIND-1))
[ "$1" = "--" ] && shift

# Define the verbose output
# -V  flag
function verbose_output {
	if [ $VERBOSE == 1 ]; then echo $1; fi;
}

# Setup the Egg Retrieval URL
EGG_URL="https://cert-api.access.redhat.com/r/insights/static/insights-client.egg"
if [ $USEGIT == 1 ]; then
	EGG_URL="https://raw.githubusercontent.com/RedHatInsights/insights-client/master/insights-client.egg"
fi

# Verbose stuff
verbose_output "Running Insights Client"

# Download the new Client Eggo if:
# 1) Not bypassed via devmode through -d flag
if [ $DEVMODE == 1 ]; then
	verbose_output "Not retrieving new Egg, running in development mode"
else
	verbose_output "Obtaining Insights Client"
	EGG_CURL=$(curl --insecure --write-out %{http_code} --silent --output insights-client.egg $EGG_URL)
	verbose_output "Client retrieval response "$EGG_CURL""
	if [ $EGG_CURL != 200 ]; then verbose_output "Egg retrieval failed"; exit 1; fi;
	if [ $EGG_CURL == 200 ]; then verbose_output "Egg retrieval success"; fi;
fi

# If we are running in development mode, build the new egg from local
if [ $DEVMODE == 1 ] && [ $DONTBUILD == 0 ]; then
	verbose_output "Running in development mode, building egg from local source"
	python setup.py bdist_egg > /dev/null 2>&1
else
	verbose_output "Not building new egg, don't build flag set"
fi



# Verify the eggo if not bypassed via -G flag
EGG_VERIFICATION=0
if [ $NOGPG == 0 ]; then
	verbose_output "Verifying egg"
	GPG_KEY="redhat.gpg"
	EGG_LOCATION="insights-client.egg"
	if [ $DEVMODE == 1 ]; then 
		GPG_KEY="redhat-dev.gpg";
		EGG_LOCATION="dist/*.egg";
	fi;
	gpg --verify $GPG_KEY $EGG_LOCATION > /dev/null 2>&1
	EGG_VERIFICATION=$?
	# Bail if it doesn't check out
	if [ $EGG_VERIFICATION != 0 ]; then
		verbose_output "Egg verification failed";
		exit 1;
	else
		verbose_output "Egg verification passed";
	fi
else
	verbose_output "Egg verification bypassed"
fi


# Hatch the egg if it checks out
# The egg will check out if:
# 1) GPG is verified
# 2) GPG is bypassed
if [ $EGG_VERIFICATION == 0 ]; then
	if [ $DEVMODE == 1 ]; then
		verbose_output "Running development egg"
		python dist/*.egg
	else
		verbose_output "Running egg from Git or Mothership"
		python insights-client.egg
	fi
fi