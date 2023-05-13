# 266 dockerfile

Pulbished to [here](https://hub.docker.com/r/ebrown/nlp-gpu-jupyter/tags)

pull:

```docker
    docker pull ebrown/nlp-gpu-jupyter:latest
```

Replace Local_Path_to_Notebooks with the path on your system. This will be mounted to /tf/notebooks in the container. This is the jupyter root directory.
run in Windows:

```docker
# in powershell, into Jupyter:
    wt -p "PowerShell" docker run -it --rm --gpus all -p 8888:8888 -p 6006:6006 -v "Local_Path_to_Notebooks:/tf/notebooks" ebrown/nlp-gpu-jupyter:latest


# in powershell, into bash:
    wt -p "PowerShell" docker run --entrypoint /bin/bash -it --rm --gpus all -p 8888:8888 -p 6006:6006 -v "Local_Path_to_Notebooks:/tf/notebooks" ebrown/nlp-gpu-jupyter:latest
```

If you're using docker compose you'll need to adjust the volume mount to reflect the location of jupyter notebooks on your system. 

run in Linux:

```docker
    docker-compose up -d
    docker-compose down
```
