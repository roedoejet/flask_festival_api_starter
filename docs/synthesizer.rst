.. _synthesizer:

Synthesizer
============

The synthesizer that is bundled in this repo is a toy synthesizer of my voice telling the time in English. I built it using Festival and following some freely available documentation and guides such as `these lecture slides <https://web.stanford.edu/class/cs224s/lectures/224s.17.lec14.pdf>`_ from Andrew Maas and `this tutorial <http://tts.speech.cs.cmu.edu/11-823/hints/clock.html>`_ by Alan Black at CMU. `Speech Zone <http://www.speech.zone/courses/speech-synthesis/>`_ is also an invaluable resource if you are beginning your learning into speech synthesis.

There are likely 3 things that you might want to do to adapt this starter, so I will provide short guides for each. 
First, you might want to 

1. Use your voice for an English talking clock
**********************************************

Here are the steps to use your voice instead of mine for the talking clock:

a. Record audio for the 24 sentences in `model/eng_clock/etc/txt.done.data`. I suggest using CSTR's `Speech Recorder <http://www.cstr.ed.ac.uk/research/projects/speechrecorder/>`_ - visit the `Speech Recorder Documentation <http://www.cstr.ed.ac.uk/research/projects/speechrecorder/SpeechRecorder_User_Guide.pdf>`_ for instructions on how to use it. They must be labelled with the same format, (ie, time0001, time0002 etc). I recommend 48KHz sample rate.

b. Move audio files to `model/eng_clock/recordings`

c. Change directories, `cd model/eng_clock`

d. Get the wavs (move to the right directly and downsample) `./bin/get_wavs recording/*.wav`

e. Prune silence `./bin/prune_silence`. Look at the files in `model/eng_clock/wavs` and see if they were pruned too much. You can fix these manually if needed.

f. Make label files `./bin/make_labs prompt-wav/*.wav`

g. Build utterance structure `$FESTIVALDIR/bin/festival -b festvox/build_ldom.scm '(build_utts "etc/txt.done.data")'`

h. Extract pitchmarks `./bin/make_pm_wave wav/*.wav`

i. Fix pitchmarks `./bin/make_pm_fix pm/*.pm`

j. Power normalize `./bin/simple_powernormalize wav/*.wav`

k. Get MCEP vectors `./bin/make_mcep wav/*.wav`

l. Build synthesizer `$FESTIVALDIR/bin/festival -b festvox/build_ldom.scm '(build_clunits "etc/txt.done.data")'`

m. Commit your changes, and either build your docker container again and run locally or push to heroku. Check the start guide for more info.

2. Build a talking clock for a different language
*************************************************

...coming...

3. Build a different synthesizer that ISN'T a talking clock
***********************************************************

...coming...