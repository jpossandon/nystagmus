# nystagmus

- image_viewing.m , psychtoolbox code for image viewing experiment, every block starts with a custom calibration trial
- do_calib.m      , 9-point custom calibration function with the eyelink system, calling it should results in the appearance a trial in the edf file       
- calibdata.m     , read calibration trials data produced by do_calib and calculated the coeficients to transform raw data to gaze data
- get_ETdataraw.m , online reading of raw data from eye-tracker
