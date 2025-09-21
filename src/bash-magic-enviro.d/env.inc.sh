# Meant to be sourced from main BME script

# "Hidden" variables (non-exported)
BME_BASEDIR=$(dirname ${BME_SCRIPT})
# BME_INCLUDES_DIR="${BME_BASEDIR}/bash-magic-enviro.d"
BME_HIDDEN_DIR='.bme.d'
BME_CONFIG_DIR="${HOME}/${BME_HIDDEN_DIR}"

BME_WHITELISTED_FILE="${BME_CONFIG_DIR}/whitelistedpaths"
BME_PROJECT_FILE='.bme_project'
BME_FILE='.bme_env'

BME_LOG_LEVEL="${BME_LOG_LEVEL:=INFO}"  # sets log level (with default)

# Sets 'fake' boolean
declare -i BOOL=(0 1)
true=${BOOL[0]}
false=${BOOL[1]}
