#!/bin/bash

usage() {
        cat <<EOF
    Usage: echo "<prompt here>" | $0 --image <imagePath> --model <modelId>
EOF
        exit 1
}



llm() {

    set -euo pipefail
    
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
    IMAGE_PATH=""
    SHOW_PROMPT=0
    while [[ "$#" -gt 0 ]]; do
      case $1 in
        --image) IMAGE_PATH="$2"; shift ;;
        --model) MODEL="$2"; shift ;;
        --show-prompt) SHOW_PROMPT=1; shift ;;
        *) usage ;;
      esac
      shift
    done
    
    # create temp files to hold base64 encoded image contents + general payload
    # we do this to circumvent bash command length limits
    tmp_image_contents=$(mktemp)
    tmp_payload_contents=$(mktemp)
    
    
    # Handle image encoding if present
    IMAGE_URL=""
    if [[ -n "${IMAGE_PATH}" ]]; then
      if [[ ! -f "${IMAGE_PATH}" ]]; then
        echo "The image path provided does not exist."
        exit 1
      fi
    
      # base64-encode the image
      BASE64_IMAGE=$(base64 -w 0 -i "${IMAGE_PATH}")
      IMAGE_URL="data:image/jpeg;base64,${BASE64_IMAGE}"
      echo "$IMAGE_URL" > "$tmp_image_contents"
    fi
    
    # TODO: ideally we could build the prompt like this instead of relying on the conditional
    #jq -n --arg model "$MODEL" --arg prompt "$PROMPT" --arg imagePath "$IMAGE_PATH" --rawfile encodedURL "$tmp_image_contents" '{"model": $model, "messages": [{"role": "user", "content": [{"type": "text", "text": $prompt}] + (if $imagePath | length > 0 then [{"type": "image_url", "image_url": {"url": $encodedURL}}] else [] end)}]}' > "$tmp_payload_contents"
    if [[ -n "$IMAGE_URL" ]]; then
        jq -n --arg model "$MODEL" --rawfile prompt /dev/stdin --rawfile encodedURL "$tmp_image_contents" \
            '{model: $model, messages: [{role: "user", content: [{type: "text", text: $prompt}, {type: "image_url", image_url: {url: $encodedURL}}]}]}' > "$tmp_payload_contents"
    else
        jq -n --arg model "$MODEL" --rawfile prompt /dev/stdin \
            '{model: $model, messages: [{role: "user", content: [{type: "text", text: $prompt}]}]}' > "$tmp_payload_contents"
    fi
    
    #cat "$tmp_payload_contents"
    curl https://api.openai.com/v1/chat/completions \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $OPENAI_API_KEY" \
      -d "@$tmp_payload_contents" 2>/dev/null | jq -r '.choices[0].message.content'
}

if [[ "$1" == "--export" ]]; then
    declare -f llm
    declare -p OPENAI_API_KEY
else
    llm "$@"
fi
