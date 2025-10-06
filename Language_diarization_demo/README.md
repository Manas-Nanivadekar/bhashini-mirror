#################################

Packages Reqiuired

pip install kaldi_io
pip install fastcluster
pip install openai-whisper
pip install pyannote.audio

##################################


##################################

Steps To Run Language Diarization on a single file

##################################


Unzip the file ld.zip

Place the audio file to be diarized in a folder and copy its path

Open terminal 

> python3 language_diarization.py audio_path

Example:

> python3 language_diarization.py /media/MyDataDrive/pratik/single_file_system_LD/B007.wav

This will create an output directory with name same as the audio file

In case you want to save the output in a directory of your choice run the command

> python3 language_diarization.py --output_dir OUTPUT_DIR audio_path

Example:

> python3 language_diarization.py --output_dir /media/MyDataDrive/pratik/single_file_system_LD/output /media/MyDataDrive/pratik/single_file_system_LD/B007.wav

## License
<a rel="license" href="http://creativecommons.org/licenses/by/4.0/"><img alt="Creative Commons Licence" style="border-width:0" src="https://i.creativecommons.org/l/by/4.0/88x31.png" /></a><br />This work is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by/4.0/">Creative Commons Attribution 4.0 International License</a>.
