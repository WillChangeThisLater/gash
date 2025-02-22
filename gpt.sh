#!/bin/bash

# Check if jq is installed
if ! command -v jq &> /dev/null
then
    echo "jq could not be found. Please install it to use this script."
    exit
fi

# Check for OpenAI API key
if [[ -z "${OPENAI_API_KEY}" ]]; then
  echo "You must set OPENAI_API_KEY environment variable."
  exit 1
fi

# Default model
MODEL="gpt-4o-mini"

# Parse input arguments
INPUT_PROMPT=""
IMAGE_PATH=""
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --image) IMAGE_PATH="$2"; shift ;;
    --model) MODEL="$2"; shift ;;
    *) INPUT_PROMPT="$1" ;;
  esac
  shift
done

# Handle image encoding if present
IMAGE_CONTENT=""
if [[ -n "${IMAGE_PATH}" ]]; then
  if [[ ! -f "${IMAGE_PATH}" ]]; then
    echo "The image path provided does not exist."
    exit 1
  fi
  BASE64_IMAGE=$(base64 -w 0 "${IMAGE_PATH}")
  IMAGE_CONTENT=', {"type": "image_url", "image_url": {"url": "data:image/jpeg;base64,'"${BASE64_IMAGE}"'"}}'
fi

# Prepare message content
CONTENT="[${INPUT_PROMPT}]$IMAGE_CONTENT"

# Create payload using jq
PAYLOAD=$(jq -n --arg model "$MODEL" --argjson messages "[{\"role\": \"user\", \"content\": [{\"type\": \"text\", \"text\": \"$INPUT_PROMPT\"}${IMAGE_PATH:+$IMAGE_CONTENT}]}]" \
'{
  model: $model,
  messages: $messages
}')

# Make API call
curl https://api.openai.com/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d "$PAYLOAD"
