# 266 dockerfile

Pulbished to [here](https://hub.docker.com/r/ebrown/nlp-gpu-jupyter/tags)

pull:

```docker
    docker pull ebrown/nlp-gpu-jupyter:latest
```

run in Windows:

```docker
# in powershell, into Jupyter:
    wt -p "PowerShell" docker run -it --rm --gpus all -p 8888:8888 -p 6006:6006 -v "C:\Users\edbrown\Documents\01-Berkeley\266:/tf/notebooks" ebrown/nlp-gpu-jupyter:latest


# in powershell, into bash:
    wt -p "PowerShell" docker run --entrypoint /bin/bash -it --rm --gpus all -p 8888:8888 -p 6006:6006 -v "C:\Users\edbrown\Documents\01-Berkeley\266:/tf/notebooks" ebrown/nlp-gpu-jupyter:latest
```

run in Linux:

```docker
    docker-compose up -d
    docker-compose down
```
