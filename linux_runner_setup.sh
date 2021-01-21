#!/bin/bash
set -eo pipefail
# Usage: Run on the machine to be configured as root
# E.g. `sudo ./linux_runner_setup.sh`
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

# Confirm installation target
PS3='Installation target?: '
options=("Linux x86_64" "Linux ARM64")
select installation_target in "${options[@]}"
do
    case $installation_target in
        "Linux x86_64")
            platform=linux/amd64
            break
            ;;
        "Linux ARM64")
            platform=linux/arm64
            break
            ;;
        *) echo "invalid option $REPLY"
    esac
done


# Ask the user for the runner auth token and runner name
echo "Runner auth token: "
read auth_token

echo "Runner name: "
read runner_name

# set boolean for working directory to be cleaned up
PS3='Cleanup working directory?: '
options=("true" "false")
select working_directory in "${options[@]}"
do
    case $working_directory in
        "true")
            WORKING_DIRECTORY=true
            break
            ;;
        "false")
            WORKING_DIRECTORY=false
            break
            ;;
        *) echo "invalid option $REPLY"
    esac
done

# From https://circleci.com/docs/2.0/runner-installation/index.html#installation
prefix=/opt/circleci
mkdir -p "$prefix/workdir"
base_url="https://circleci-binary-releases.s3.amazonaws.com/circleci-launch-agent"
echo "Determining latest version of CircleCI Launch Agent"
agent_version=$(curl "$base_url/release.txt")
echo "Using CircleCI Launch Agent version $agent_version"
echo "Downloading and verifying CircleCI Launch Agent Binary"
curl -sSL "$base_url/$agent_version/checksums.txt" -o checksums.txt
file="$(grep -F "$platform" checksums.txt | cut -d ' ' -f 2)"
file="${file:1}"
mkdir -p "$platform"
echo "Downloading CircleCI Launch Agent: $file"
curl --compressed -L "$base_url/$agent_version/$file" -o "$file"
echo "Verifying CircleCI Launch Agent download"
if ! sha256sum --check --ignore-missing checksums.txt; then
    echo "Invalid checksum for CircleCI Launch Agent, please try download again"
    exit 1
fi
chmod u+x "$file"
cp "$file" "$prefix/circleci-launch-agent"

#https://circleci.com/docs/2.0/runner-installation/index.html#installing-the-circleci-runner-on-linux
mkdir -p '/opt/circleci'
cat > '/opt/circleci/launch-agent-config.yaml' << EOM
api:
  auth_token: $auth_token
runner:
  name: $runner_name
  command_prefix: ["/opt/circleci/launch-task"]
  working_directory: /opt/circleci/workdir/%s
  cleanup_working_directory: $WORKING_DIRECTORY
EOM

chmod 600 /opt/circleci/launch-agent-config.yaml

#https://circleci.com/docs/2.0/runner-installation/index.html#create-the-circleci-user-working-directory
id -u circleci &>/dev/null || adduser --uid 1500 --disabled-password --gecos GECOS circleci

mkdir -p /opt/circleci/workdir
chown -R circleci /opt/circleci/workdir

#https://circleci.com/docs/2.0/runner-installation/index.html#install-the-launch-script
echo "Installing the launch script"
mkdir -p /opt/circleci

cat > '/opt/circleci/launch-task' << EOM
#!/bin/bash
set -euo pipefail
## This script launches the build-agent using systemd-run in order to create a
## cgroup which will capture all child processes so they're cleaned up correctly
## on exit.
# The user to run the build-agent as - must be numeric
USER_ID=$(id -u circleci)
# Give the transient systemd unit an inteligible name
unit="circleci-$CIRCLECI_LAUNCH_ID"
# When this process exits, tell the systemd unit to shut down
abort() {
  if systemctl is-active --quiet "$unit"; then
    systemctl stop "$unit"
  fi
}
trap abort EXIT
systemd-run \
    --pipe --collect --quiet --wait \
    --uid "$USER_ID" --unit "$unit" -- "$@"
EOM

chmod 755 /opt/circleci/launch-task

cat > '/opt/circleci/circleci.service' << EOM 
[Unit]
Description=CircleCI Runner
After=network.target
[Service]
ExecStart=/opt/circleci/circleci-launch-agent --config /opt/circleci/launch-agent-config.yaml
Restart=always
User=root
NotifyAccess=exec
TimeoutStopSec=18300
[Install]
WantedBy = multi-user.target
EOM

chmod 755 /opt/circleci/circleci.service

prefix=/opt/circleci
echo "Enabling the service..."
systemctl enable $prefix/circleci.service

echo "Starting the service..."
systemctl start circleci.service

echo "Checking the status... "
systemctl status circleci.service --no-pager

echo "Checking logs... "
journalctl -u circleci
