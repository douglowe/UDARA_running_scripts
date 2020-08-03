# UDARA_running_scripts

Running scripts for UDARA project. These will include NCL data extraction scripts.

Once you've cloned the repository you will need to invoke te git submodule command to load
the required libraries:
```
git submodule init
git submodule update
```

Your running scripts will also need the `WRF_NCL_ROOT` environmental variable to be set,
e.g.:
```
export WRF_NCL_ROOT=[path to repository directory]/Data_Extraction_Scripts/
```
