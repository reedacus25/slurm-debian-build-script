Simple bash script to build debs for slurm.
Includes the nvidia NVML libraries for discovering GPUs.
  This was not very well documented...

I also append the OS codename (focal, jammy, noble, etc) to the end of the debs so that I can publish these packages from a single publish point in aptly.

Tried to make it at least somewhat [Ubuntu LTS] OS independent.
