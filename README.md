## What is this?
A bash script for calling OpenAI API endpoint

## Normal usage
```bash
$ echo "What does this script do? $(cat -n gash.sh)" | ./gash.sh
```

```bash
$ echo "What is this an image of?" | ./gash.sh --image assets/rome.jpg
```

## Black magic
```bash
$ docker run -it --rm ubuntu bash -c "$(./gash.sh --export); export -f llm; apt update && apt install curl jq vim -y; bash"
```

and you should be able to run commands in containers
