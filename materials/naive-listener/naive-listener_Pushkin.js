// This code generates the naïve listener experiment run in Hilton & Moser et al. (2022).
// You can try the experiment at https://themusiclab.org/quizzes/ids.
//
// WARNING: 
// This code is not executable outside of a Pushkin instance. It is posted here for transparency only.
// A working standalone jsPsych version of this experiment is available at https://github.com/themusiclab/infant-speech-song.

/* eslint-disable max-len */
require('script-loader!jspsych/jspsych.js');

require("script-loader!jspsych/plugins/jspsych-html-keyboard-response.js");
require("script-loader!jspsych/plugins/jspsych-html-button-response.js");

require('script-loader!../common/custom-plugins/jspsych-audio-button-response-vert.js');
require("script-loader!../common/custom-plugins/jspsych-html-button-response-vert.js");
require("script-loader!../common/custom-plugins/jspsych-audio-imageButton-response-loop.js");
require("script-loader!../common/custom-plugins/jspsych-audio-imageButton-response-training-loop.js");
require("script-loader!../common/custom-plugins/jspsych-audio-keyboard-response-loop.js");
require("script-loader!../common/custom-plugins/jspsych-audio-keyboard-response-training-loop.js");

import '../common/custom-plugins/jspsych-react.js';

import React from 'react';
import ExperimentEndPage from '../../components/ExperimentEndPage';
import ReactMap from '../../components/charts/Map';

import isMobile from '../common/isMobile';
import experimentInfo from './info';
import api from '../common/api';
import baseUrl from '../../core/baseUrl';

import {
  labelR,
  imgR,
  imgData1,
  imgData2,
  tracksE,
  tracksNE
} from './common/idsInfo';

import {
  intro,
  musicxp,
  demog,
  // muppet items
  musicTalent,
  musicListenPleasure,
  musicPleasure,
  singingChoir,
  // end
  email
} from '../common/covariates';

import {template as socialTemplate} from "../common/social.js";

var mobile = isMobile();

export default function startExperiment(options) {
  api.init(experimentInfo, options);

    const timeline = [];
    const dataArray = [];
    let stims;
    let user;
    let count;
    let reactionMean;

    jsPsych.data.addProperties({ image_order1: imgData1 });

    var tracksRE = jsPsych.randomization.sampleWithoutReplacement(tracksE, 4);
    var tracksRNE = jsPsych.randomization.sampleWithoutReplacement(tracksNE, 12);
    var tracks = tracksRE.concat(tracksRNE);
    var tracksR = jsPsych.randomization.shuffle(tracks);

    var song_list = [];
    let current;
    let percentile;
    let lat;
    let lng;

    for (var i = 0; i < 16; i++) {
      current = {
        stimulus: `${baseUrl}/quizzes/fc/audio/${tracksR[i].stimulus}.mp3`,
        data: mobile ? tracksR[i].data2 : tracksR[i].data1,
        lat: tracksR[i].latitude,
        lng: tracksR[i].longitude,
      };
      song_list.push(current);
    }

    /* generic welcome */
    var welcome = {
      type: 'html-button-response',
      stimulus: '<p align="left">This experiment is being conducted by researchers at Harvard University. Before you decide to participate, please read the following information.</p><p align="left">We study how the mind works. Specifically, in this research we are investigating how people make sense of music they hear. We will play you some sounds. You can use speakers or headphones. We will ask you questions about what you hear. The experiment takes less than 10 minutes.</p><p align="left">We will ask you to answer questions concerning your emotions and behaviors, your preferences and beliefs about music and the arts, your engagement with musical activities, your personal history of musical exposure and training, and some demographic information about you and your family. We will also ask you to look at pictures or words and respond to them. This helps us to understand a bit more about how you are feeling. For example, you might feel especially happy or sad while playing our games, and this task helps us to measure how happy or sad you feel.</p><p align="left">This research has no known risks or anticipated direct benefits. You will not receive compensation for participating in this experiment. Your participation in this research is completely voluntary. You can end your participation at any time without penalty.</p><p align="left">Your participation is completely anonymous. Your responses will be stored securely on a server at Harvard University under password protection. Your experiment data may be shared with other researchers. The results and data from this experiment will be shared with the public. After the experiment, we will explain several ways to be informed about the research. If you have questions or problems, you can contact us at <a href="mailto:musiclab+tml@g.harvard.edu" target="_blank">musiclab+tml@g.harvard.edu</a>. By proceeding, you agree to participate in this experiment.</p>',
      prompt1: ' ',
      prompt2: ' ',
      choices: ['Next'],
      on_finish: function(data){
        api.onStartExperiment();
        api.saveDataOnFinish(data)
      }
    };

    var whichHands = {
      type: 'html-keyboard-response',
      stimulus: '<p>For this game, you will be using the <b>F</b> and <b>J</b> keys.</p><p>Place your hands on the keyboard, like this.</p><p><img src='+`${baseUrl}/quizzes/fc/img/fj_hands_animate.gif`+' align="center" width="500px"></p><p>This will help you to enter your answers quickly during the game.<br/>Press any key to continue.</p>',
      prompt: '',
      on_finish: function(data){
        api.saveDataOnFinish(data)
      }
    };

    /* intro to quiz */
    var ready = {
      type: mobile ? 'html-button-response' : 'html-keyboard-response',
      stimulus: '<p align="center">In this game, we\'ll play you recordings of people from all over the world. They will either be <b>singing</b> or <b>speaking</b>. We\'ll ask you to tell us <b>who you think is listening</b>: a baby or an adult.</p><p align="center">For example, if you hear someone singing a lullaby, you might answer that you think a <b>baby</b> is listening.</p><p align="center">Try to answer as fast as you can!</p>'+`${mobile ? '' : '<p align="center">Press any key to continue.</p>'}`,
      prompt1: '',
      prompt2: '',
      choices: mobile ? ['Next'] : jsPsych.ALL_KEYS,
      on_finish: function(data){
        api.saveDataOnFinish(data)
      }
    };

    /* training */
    let reactionT;
    /* baby */
    var trainInfo1B = {
      type: mobile ? 'html-button-response' : 'html-keyboard-response',
      stimulus: '<p align="center">First, let\'s practice! The first excerpt you will hear is a song sung to a baby. So you should choose the <b>BABY</b> character for your response.</p><p><img src='+`${baseUrl}/quizzes/fc/img/baby.jpg`+' width='+`${mobile ? '150' : '350'}`+'><br>The <b>BABY</b> character looks like this.</p><p align="center">Try to answer as fast as you can!' +`${mobile ? '' : ' Press any key to continue.</p>'}`,
      prompt1: '',
      prompt2: '',
      choices: mobile ? ['Let\'s begin!'] : jsPsych.ALL_KEYS,
      on_finish: function(data){
        api.saveDataOnFinish(data)
      }
    };
    var trainData1B = [
      { stimulus: `${baseUrl}/quizzes/fc/audio/TOR47A.mp3`, data: mobile ? imgData2[0] : imgData1[0] }
    ];
    var training1B = {
      timeline: [
        {
          type: mobile ? 'audio-imageButton-response-training-loop' : 'audio-keyboard-response-training-loop',
          stimulus: jsPsych.timelineVariable('stimulus'),
          data: jsPsych.timelineVariable('data'),
          choices: mobile ? [imgR[0], imgR[1]] : ['f', 'j'],
          prompt: '<p align="center">Someone is speaking or singing. Who do you think they are singing or speaking to?</p>'+`${mobile ? '<p align="center">Tap the character being sung to!</p>'
            : '<div>Press <b>F</b> for ' +
            labelR[0] +
            ' or <b>J</b> for ' +
            labelR[1] +
            '. </div><br><table align="center" width=80%><tr><td><img src=' +
            imgR[0] +
            ' width=90%>&nbsp;&nbsp;</td><td>&nbsp;&nbsp;<img src=' +
            imgR[1] +
            ' width=90%></td></tr><tr><td>&nbsp;<b>F</b>&nbsp;</td><td>&nbsp;<b>J</b>&nbsp;</td></tr></table><br><p>Try to answer as quickly as you can!</p>'}`,
          response_ends_trial: true,
          on_finish: function(data) {
            mobile ? data.correct1 = data.button_pressed == data.button : data.correct1 = data.key_press == jsPsych.pluginAPI.convertKeyCharacterToKeyCode(data.key);
            console.log(JSON.stringify(data));
            reactionT = Math.round(data.rt / 1000 * 10) / 10;
            console.log(reactionT);
            api.saveDataOnFinish(data);
          }
        },
        {
          type: mobile ? 'html-button-response-vert' : 'html-keyboard-response',
          stimulus: function() {
            var correct = jsPsych.data.get().last(1).values()[0].correct1;
            var key = jsPsych.data.get().last(1).values()[0].key_press;
            var button = jsPsych.data.get().last(1).values()[0].button_pressed;
            if (correct == true && key == '70') {
              return (
                `<div style="font-size:24px"><font color="#00cc00">Correct!</font></div><div style="font-size:18px">You responded in <b>` +
                reactionT +
                ` seconds</b>.</div><div>Press any key to continue.</div><table align="center" width=80%><tr><td><img src="` +
                imgR[0] +
                `" width=90%>&nbsp;&nbsp;</td><td>&nbsp;&nbsp;<img src=${baseUrl}/quizzes/fc/img/white.jpg width=90%></td></tr></table>`
              );
            } else if (correct == true && key == '74') {
              return (
                `<div style="font-size:24px"><font color="#00cc00">Correct!</font></div><div style="font-size:18px">You responded in <b>` +
                reactionT +
                ` seconds</b>.</div><div>Press any key to continue.</div><table align="center" width=80%><tr><td><img src=${baseUrl}/quizzes/fc/img/white.jpg width=90%>&nbsp;&nbsp;</td><td>&nbsp;&nbsp;<img src="` +
                imgR[1] +
                `" width=90%></td></tr></table>`
              );
            } else if (correct == false && key == '70') {
              return (
                `<div style="font-size:24px"><font color="red">Incorrect.</font></div><div style="font-size:18px">You responded in <b>` +
                reactionT +
                ` seconds</b>.</div><div>Press any key to try again!</div><table align="center" width=80%><tr><td><img src=${baseUrl}/quizzes/fc/img/incorrect.jpg width=90%>&nbsp;&nbsp;</td><td>&nbsp;&nbsp;<img src=${baseUrl}/quizzes/fc/img/white.jpg width=90%></td></tr></table>`
              );
            } else if (correct == false && key == '74') {
              return (
                `<div style="font-size:24px"><font color="red">Incorrect.</font></div><div style="font-size:18px">You responded in <b>` +
                reactionT +
                ` seconds</b>.</div><div>Press any key to try again!</div><table align="center" width=80%><tr><td><img src=${baseUrl}/quizzes/fc/img/white.jpg width=90%>&nbsp;&nbsp;</td><td>&nbsp;&nbsp;<img src=${baseUrl}/quizzes/fc/img/incorrect.jpg width=90%></td></tr></table>`
              );
            } else if(correct == true && button== 0) {
              return '<div style="display: inline-block; margin:0px 8px;"><img src="'+imgR[0]+'" width=150px align="left"></div><p align="center"><div style="font-size:24px"><font color="#00cc00">Correct!</font></div></p><p>You responded in '+reactionT+' seconds.</p>';
            } else if(correct == true && button== 1) {
              return '<div style="display: inline-block; margin:0px 8px;"><img src="'+`${baseUrl}/quizzes/fc/img/white.jpg`+'" width=150px align="right"></div><p align="center"><div style="font-size:24px"><font color="#00cc00">Correct!</font></div></p><p>You responded in '+reactionT+' seconds.</p>';
            } else if(correct == false && button==0) {
              return '<div style="display: inline-block; margin:0px 8px;"><img src='+`${baseUrl}/quizzes/fc/img/incorrect.jpg`+' width=150px align="right"></div><p align="center"><div style="font-size:24px"><font color="red">Incorrect.</font></div></p><p>You responded in '+reactionT+' seconds.<br>Try again!</p>';
            } else if(correct == false && button==1) {
              return '<div style="display: inline-block; margin:0px 8px;"><img src='+`${baseUrl}/quizzes/fc/img/white.jpg`+' width=150px align="right"></div><p align="center"><div style="font-size:24px"><font color="red">Incorrect.</font></div></p><p>You responded in '+reactionT+' seconds.<br>Try again!</p>';
            }
          },
          choices: mobile ? ['Next'] : jsPsych.ALL_KEYS,
          prompt: mobile ? function(){
    				var correct = jsPsych.data.get().last(1).values()[0].correct1;
    				var button = jsPsych.data.get().last(1).values()[0].button_pressed;
    				if(correct == true && button== 0)
    					{return '<div style="display: inline-block; margin:0px 8px;"><img src='+`${baseUrl}/quizzes/fc/img/white.jpg`+' width=150px align="right"></div>';}
    				else if(correct == true && button== 1)
    					{return '<div style="display: inline-block; margin:0px 8px;"><img src="'+imgR[1]+'" width=150px align="right"></div>';}
    				else if(correct == false && button==0)
    					{return '<div style="display: inline-block; margin:0px 8px;"><img src='+`${baseUrl}/quizzes/fc/img/white.jpg`+' width=150px align="right"></div>';}
    				else if(correct == false && button==1)
    					{return '<div style="display: inline-block; margin:0px 8px;"><img src='+`${baseUrl}/quizzes/fc/img/incorrect.jpg`+' width=150px align="right"></div>';}
    			} : '',
          on_finish: function(data){
            api.saveDataOnFinish(data)
          }
        }
      ],
      timeline_variables: trainData1B,
      sample: {
        size: 1,
        type: 'without-replacement'
      }
    };
    var reTrain1B = {
      timeline: [training1B],
      loop_function: function(data) {
        if (jsPsych.pluginAPI.convertKeyCharacterToKeyCode(imgData1[1].key) == data.values()[0].key_press || imgData2[1].button == data.values()[0].button_pressed) {
          return true;
        } else {
          return false;
        }
      }
    };
    var trainInfo1A = {
      type: mobile ? 'html-button-response' : 'html-keyboard-response',
      stimulus:
        '<p align="center">Let\'s practice a second time. This next excerpt will be directed toward an adult, so you should choose the <b>ADULT</b> character.</p><p><img src=' +
        `${baseUrl}/quizzes/fc/img/adult.jpg` +
        ' width='+`${mobile ? '150' : '350'}`+'><br>The <b>ADULT</b> character looks like this.</p><p align="center">Try to answer as quickly as possible! '+`${mobile ? '' : ' Press any key to continue.</p>'}`,
      choices: mobile ? ['Continue'] : jsPsych.ALL_KEYS,
      on_finish: function(data){
        api.saveDataOnFinish(data)
      }
    };
    /* adult */
    var trainData1A = [
      { stimulus: `${baseUrl}/quizzes/fc/audio/WEL10C.mp3`, data: mobile ? imgData2[1] : imgData1[1] }
    ];
    var training1A = {
      timeline: [
        {
          type: mobile ? 'audio-imageButton-response-training-loop' : 'audio-keyboard-response-training-loop',
          stimulus: jsPsych.timelineVariable('stimulus'),
          data: jsPsych.timelineVariable('data'),
          choices: mobile ? [imgR[0], imgR[1]] : ['f', 'j'],
          prompt: '<p align="center">Someone is speaking or singing. Who do you think they are singing or speaking to?</p>'+`${mobile ? '<p align="center">Tap the character being sung to!</p>'
            : '<div>Press <b>F</b> for ' +
            labelR[0] +
            ' or <b>J</b> for ' +
            labelR[1] +
            '. </div><br><table align="center" width=80%><tr><td><img src=' +
            imgR[0] +
            ' width=90%>&nbsp;&nbsp;</td><td>&nbsp;&nbsp;<img src=' +
            imgR[1] +
            ' width=90%></td></tr><tr><td>&nbsp;<b>F</b>&nbsp;</td><td>&nbsp;<b>J</b>&nbsp;</td></tr></table><br><p>Try to answer as quickly as you can!</p>'}`,
          response_ends_trial: true,
          on_finish: function(data) {
            mobile ? data.correct1 = data.button_pressed == data.button : data.correct1 = data.key_press == jsPsych.pluginAPI.convertKeyCharacterToKeyCode(data.key);
            console.log(JSON.stringify(data));
            reactionT = Math.round(data.rt / 1000 * 10) / 10;
            console.log(reactionT);
            api.saveDataOnFinish(data)
          }
        },
        {
          type: mobile? 'html-button-response-vert' : 'html-keyboard-response',
          stimulus: function() {
            var correct = jsPsych.data.get().last(1).values()[0].correct1;
            var key = jsPsych.data.get().last(1).values()[0].key_press;
            var button = jsPsych.data.get().last(1).values()[0].button_pressed;
            if (correct == true && key == '70') {
              return (
                `<div style="font-size:24px"><font color="#00cc00">Correct!</font></div><div style="font-size:18px">You responded in <b>` +
                reactionT +
                ` seconds</b>.</div><div>Press any key to continue.</div><table align="center" width=80%><tr><td><img src="` +
                imgR[0] +
                `" width=90%>&nbsp;&nbsp;</td><td>&nbsp;&nbsp;<img src=${baseUrl}/quizzes/fc/img/white.jpg width=90%></td></tr></table>`
              );
            } else if (correct == true && key == '74') {
              return (
                `<div style="font-size:24px"><font color="#00cc00">Correct!</font></div><div style="font-size:18px">You responded in <b>` +
                reactionT +
                ` seconds</b>.</div><div>Press any key to continue.</div><table align="center" width=80%><tr><td><img src=${baseUrl}/quizzes/fc/img/white.jpg width=90%>&nbsp;&nbsp;</td><td>&nbsp;&nbsp;<img src="` +
                imgR[1] +
                `" width=90%></td></tr></table>`
              );
            } else if (correct == false && key == '70') {
              return (
                `<div style="font-size:24px"><font color="red">Incorrect.</font></div><div style="font-size:18px">You responded in <b>` +
                reactionT +
                ` seconds</b>.</div><div>Press any key to try again!</div><table align="center" width=80%><tr><td><img src=${baseUrl}/quizzes/fc/img/incorrect.jpg width=90%>&nbsp;&nbsp;</td><td>&nbsp;&nbsp;<img src=${baseUrl}/quizzes/fc/img/white.jpg width=90%></td></tr></table>`
              );
            } else if (correct == false && key == '74') {
              return (
                `<div style="font-size:24px"><font color="red">Incorrect.</font></div><div style="font-size:18px">You responded in <b>` +
                reactionT +
                ` seconds</b>.</div><div>Press any key to try again!</div><table align="center" width=80%><tr><td><img src=${baseUrl}/quizzes/fc/img/white.jpg width=90%>&nbsp;&nbsp;</td><td>&nbsp;&nbsp;<img src=${baseUrl}/quizzes/fc/img/incorrect.jpg width=90%></td></tr></table>`
              );
            } else if(correct == true && button== 0) {
              return '<div style="display: inline-block; margin:0px 8px;"><img src="'+imgR[0]+'" width=150px align="left"></div><p align="center"><div style="font-size:24px"><font color="#00cc00">Correct!</font></div></p><p>You responded in '+reactionT+' seconds.</p>';
            } else if(correct == true && button== 1) {
              return '<div style="display: inline-block; margin:0px 8px;"><img src='+`${baseUrl}/quizzes/fc/img/white.jpg`+' width=150px align="left"></div><p align="center"><div style="font-size:24px"><font color="#00cc00">Correct!</font></div></p><p>You responded in '+reactionT+' seconds.</p>';
            } else if(correct == false && button==0) {
              return '<div style="display: inline-block; margin:0px 8px;"><img src='+`${baseUrl}/quizzes/fc/img/incorrect.jpg`+' width=150px align="left"></div><p align="center"><div style="font-size:24px"><font color="red">Incorrect.</font></div></p><p>You responded in '+reactionT+' seconds.<br>Try again!</p>';
            } else if(correct == false && button==1) {
              return '<div style="display: inline-block; margin:0px 8px;"><img src='+`${baseUrl}/quizzes/fc/img/white.jpg`+' width=150px align="left"></div><p align="center"><div style="font-size:24px"><font color="red">Incorrect.</font></div></p><p>You responded in '+reactionT+' seconds.<br>Try again!</p>';
            }
          },
          choices: mobile ? ['Next'] : jsPsych.ALL_KEYS,
          prompt: mobile ? function(){
    				var correct = jsPsych.data.get().last(1).values()[0].correct1;
    				var button = jsPsych.data.get().last(1).values()[0].button_pressed;
    				if(correct == true && button== 0)
    					{return '<div style="display: inline-block; margin:0px 8px;"><img src='+`${baseUrl}/quizzes/fc/img/white.jpg`+' width=150px align="right"></div>';}
    				else if(correct == true && button== 1)
    					{return '<div style="display: inline-block; margin:0px 8px;"><img src="'+imgR[1]+'" width=150px align="right"></div>';}
    				else if(correct == false && button==0)
    					{return '<div style="display: inline-block; margin:0px 8px;"><img src='+`${baseUrl}/quizzes/fc/img/white.jpg`+' width=150px align="right"></div>';}
    				else if(correct == false && button==1)
    					{return '<div style="display: inline-block; margin:0px 8px;"><img src='+`${baseUrl}/quizzes/fc/img/incorrect.jpg`+' width=150px align="right"></div>';}
    			} : '',
          on_finish: function(data){
            api.saveDataOnFinish(data)
          }
        }
      ],
      timeline_variables: trainData1A,
      sample: {
        size: 1,
        type: 'without-replacement'
      }
    };
    var reTrain1A = {
      timeline: [training1A],
      loop_function: function(data) {
        if (jsPsych.pluginAPI.convertKeyCharacterToKeyCode(imgData1[0].key) == data.values()[0].key_press || imgData2[0].button == data.values()[0].button_pressed) {
          return true;
        } else {
          return false;
        }
      }
    };

    /* real study begins here! */
    var introTest = {
      type: mobile ? 'html-button-response' : 'html-keyboard-response',
      stimulus: '<p>Great work on the practice! Now you\'re ready to begin.</p>'+`${mobile ? '' : '<p>Press any key to continue.</p>'}`,
      choices: mobile ? ['Begin'] : jsPsych.ALL_KEYS,
      on_finish: function(data){
        api.saveDataOnFinish(data)
      }
    };
    var songTest = {
      timeline: [
        {
          type: mobile ? 'audio-imageButton-response-loop' : 'audio-keyboard-response-loop',
          stimulus: jsPsych.timelineVariable('stimulus'),
          data: jsPsych.timelineVariable('data'),
          choices: mobile ? [imgR[0], imgR[1]] : ['f', 'j'],
          prompt: '<p align="center">Someone is speaking or singing. Who do you think they are singing or speaking to?</p>'+`${mobile ? '<p align="center">Tap the character being sung to!</p>'
            : '<div>Press <b>F</b> for ' +
            labelR[0] +
            ' or <b>J</b> for ' +
            labelR[1] +
            '. </div><br><table align="center" width=80%><tr><td><img src=' +
            imgR[0] +
            ' width=90%>&nbsp;&nbsp;</td><td>&nbsp;&nbsp;<img src=' +
            imgR[1] +
            ' width=90%></td></tr><tr><td>&nbsp;<b>F</b>&nbsp;</td><td>&nbsp;<b>J</b>&nbsp;</td></tr></table><br><p>Try to answer as quickly as you can!</p>'}`,
          response_ends_trial: true,
          on_finish: function(data) {
            mobile ? data.correct = data.button_pressed == data.button : data.correct = data.key_press == jsPsych.pluginAPI.convertKeyCharacterToKeyCode(data.key);
            count = jsPsych.data.get().filter({ correct: true }).count();
            reaction = Math.round(data.rt / 1000 * 10) / 10;
            lat = data.lat;
            lng = data.lng;
            console.log(count);
            if (count == "16") percentile = "100%";
            if (count == "15") percentile = "99.8%";
            if (count == "14") percentile = "98%";
            if (count == "13") percentile = "93%";
            if (count == "12") percentile = "81%";
            if (count == "11") percentile = "63%";
            if (count == "10") percentile = "43%";
            if (count == "9") percentile = "26%";
            if (count == "8") percentile = "14%";
            if (count == "7") percentile = "6%";
            if (count == "6") percentile = "2%";
            if (count <= "5") percentile = "1%";
            console.log('percentile')
            api.saveDataOnFinish(data)
          }
        },
        {
          type: mobile ? 'html-button-response-vert' : 'html-keyboard-response',
          stimulus: function() {
            var correct = jsPsych.data.get().last(1).values()[0].correct;
            console.log(correct);
            var key = jsPsych.data.get().last(1).values()[0].key_press;
            var button = jsPsych.data.get().last(1).values()[0].button_pressed;
            if (correct == true && key == '70') {
              return (
                `<div style="font-size:24px"><font color="#00cc00">Correct!</font></div><div style="font-size:18px">You responded in <b>` +reaction +` seconds</b>.</div><div>Press any key to continue.</div><table align="center" width=80%><tr><td><img src="` +imgR[0] +`" width=90%>&nbsp;&nbsp;</td><td>&nbsp;&nbsp;<img src=${baseUrl}/quizzes/fc/img/white.jpg width=90%></td></tr></table>`);
              } else if (correct == true && key == '74') {
                return (
                  `<div style="font-size:24px"><font color="#00cc00">Correct!</font></div><div style="font-size:18px">You responded in <b>` +reaction +` seconds</b>.</div><div>Press any key to continue.</div><table align="center" width=80%><tr><td><img src=${baseUrl}/quizzes/fc/img/white.jpg width=90%>&nbsp;&nbsp;</td><td>&nbsp;&nbsp;<img src="` +imgR[1] +`" width=90%></td></tr></table>`
                );
              } else if (correct == false && key == '70') {
                return (
                  `<div style="font-size:24px"><font color="red">Incorrect.</font></div><div style="font-size:18px">You responded in <b>` +reaction +` seconds</b>.</div><div>Press any key to try again!</div><table align="center" width=80%><tr><td><img src=${baseUrl}/quizzes/fc/img/incorrect.jpg width=90%>&nbsp;&nbsp;</td><td>&nbsp;&nbsp;<img src=${baseUrl}/quizzes/fc/img/white.jpg width=90%></td></tr></table>`
                );
              } else if (correct == false && key == '74') {
                return (
                  `<div style="font-size:24px"><font color="red">Incorrect.</font></div><div style="font-size:18px">You responded in <b>` +reaction +` seconds</b>.</div><div>Press any key to try again!</div><table align="center" width=80%><tr><td><img src=${baseUrl}/quizzes/fc/img/white.jpg width=90%>&nbsp;&nbsp;</td><td>&nbsp;&nbsp;<img src=${baseUrl}/quizzes/fc/img/incorrect.jpg width=90%></td></tr></table>`
                );
              } else if (correct == true && button== 0) {
                return '<div style="display: inline-block; margin:0px 8px;"><img src="'+imgR[0]+'" width=150px align="left"></div><p align="center"><div style="font-size:24px"><font color="#00cc00">Correct!</font></div></p><p>You responded in '+reaction+' seconds.</p>';
              } else if (correct == true && button== 1) {
                return '<div style="display: inline-block; margin:0px 8px;"><img src='+`${baseUrl}/quizzes/fc/img/white.jpg`+' width=150px align="left"></div><p align="center"><div style="font-size:24px"><font color="#00cc00">Correct!</font></div></p><p>You responded in '+reaction+' seconds.</p>';
              } else if (correct == false && button==0) {
                return '<div style="display: inline-block; margin:0px 8px;"><img src='+`${baseUrl}/quizzes/fc/img/incorrect.jpg`+' width=150px align="left"></div><p align="center"><div style="font-size:24px"><font color="red">Incorrect.</font></div></p><p>You responded in '+reaction+' seconds.<br>Try again!</p>';
              } else if (correct == false && button==1) {
                return '<div style="display: inline-block; margin:0px 8px;"><img src='+`${baseUrl}/quizzes/fc/img/white.jpg`+' width=150px align="left"></div><p align="center"><div style="font-size:24px"><font color="red">Incorrect.</font></div></p><p>You responded in '+reaction+' seconds.<br>Try again!</p>';
              }
          },
          choices: mobile ? ['Next'] : jsPsych.ALL_KEYS,
          prompt: mobile ? function(){
    				var correct = jsPsych.data.get().last(1).values()[0].correct;
    				var button = jsPsych.data.get().last(1).values()[0].button_pressed;
    				if(correct == true && button== 0)
    					{return '<div style="display: inline-block; margin:0px 8px;"><img src='+`${baseUrl}/quizzes/fc/img/white.jpg`+' width=150px align="right"></div>';}
    				else if(correct == true && button== 1)
    					{return '<div style="display: inline-block; margin:0px 8px;"><img src="'+imgR[1]+'" width=150px align="right"></div>';}
    				else if(correct == false && button==0)
    					{return '<div style="display: inline-block; margin:0px 8px;"><img src='+`${baseUrl}/quizzes/fc/img/white.jpg`+' width=150px align="right"></div>';}
    				else if(correct == false && button==1)
    					{return '<div style="display: inline-block; margin:0px 8px;"><img src='+`${baseUrl}/quizzes/fc/img/incorrect.jpg`+' width=150px align="right"></div>';}
    			} : '',
          on_finish: function(data) {
            reactionMean = mobile ? Math.round(jsPsych.data.get().filter({trial_type: 'audio-imageButton-response-loop'}).select('rt').mean()/1000*10)/10
            : Math.round(jsPsych.data.get().filter({trial_type:'audio-keyboard-response-loop'}).select('rt').mean()/1000*10)/10;
            trialCount = jsPsych.data.get().filter({ trial_type: 'audio-keyboard-response-loop' }).count();
            console.log(reactionMean);
            console.log(trialCount);
            api.saveDataOnFinish(data)
          }
        }
      ],
      timeline_variables: song_list,
      sample: {
        size: 16,
        type: 'without-replacement'
      }
    };

    var transition = {
      type: 'html-button-response',
      stimulus: '<p>We have just a few questions for you before we compute your score.</p>',
      prompt1: '',
      prompt2: '',
      choices: ['Continue'],
      on_finish: function(data){
        api.saveDataOnFinish(data);
      }
    };

    let reaction;
    let trialCount;

    /* debrief */
    var social = {
      type: 'react',
      on_start: function(){
        api.onFinishExperiment();
      },
      component: () => {
        let post = `I scored ${count}/16 on the Who’s Listening? game. Can you beat me? Be a citizen scientist at http://themusiclab.org!`;

        let songsHeard = [
          {stimulus: song_list[0].stimulus, location: [song_list[0].lat, song_list[0].lng]},
          {stimulus: song_list[1].stimulus, location: [song_list[1].lat, song_list[1].lng]},
          {stimulus: song_list[2].stimulus, location: [song_list[2].lat, song_list[2].lng]},
          {stimulus: song_list[3].stimulus, location: [song_list[3].lat, song_list[3].lng]},
          {stimulus: song_list[4].stimulus, location: [song_list[4].lat, song_list[4].lng]},
          {stimulus: song_list[5].stimulus, location: [song_list[5].lat, song_list[5].lng]}
        ];

        return (
          <ExperimentEndPage id={experimentInfo.id} shareTitle={post}>
            <p align="center" style={{color: '#008000', fontSize: '24px'}}>
              You listened to <b>16</b> clips. Of those you guessed <b>{count}</b> correctly!
            </p>
            <p align="center">
              You did as well as or better than <b>{percentile}</b> of people. Your average speed was <b>{reactionMean} seconds</b>.
            </p>

            <br/>

            <p align="left">
              The clips of singing and speaking you just heard were collected from all over the world from various cultures, including remote, small-scale societies. We worked with anthropologists and ethnomusicologists to collect all these recordings. They asked people to demonstrate how they would sing and speak to a fussy baby, and how they would sing and speak to an adult.
            </p>
            <p align="left">
              We will use your responses to figure out if there are reliable differences between the vocalizations people make for infants and the vocalizations people make for adults, and if those differences depend on whether the vocalizations are songs or speech.
            </p>
            <p align="left">
              Keep in touch with us in the next few months to find out the answer! You can also follow us on <a href="https://twitter.com/_themusiclab" target="_blank">Twitter</a> or <a href="https://www.facebook.com/harvardmusiclab" target="_blank">Facebook</a> to hear updates about our findings.
            </p>
            <p align="left">Keep in touch with us in the next few months to find out the answer!</p>
          </ExperimentEndPage>
        )
      }
    };

    var audioPreload = [
      song_list[0].stimulus,
      song_list[1].stimulus,
      song_list[2].stimulus,
      song_list[3].stimulus,
      song_list[4].stimulus,
      song_list[5].stimulus,
      song_list[6].stimulus,
      song_list[7].stimulus,
      song_list[8].stimulus,
      song_list[9].stimulus,
      song_list[10].stimulus,
      song_list[11].stimulus,
      song_list[12].stimulus,
      song_list[13].stimulus,
      song_list[14].stimulus,
      song_list[15].stimulus,
      `${baseUrl}/quizzes/fc/audio/WEL10C.mp3`,
      `${baseUrl}/quizzes/fc/audio/TOR47A.mp3`,
      `${baseUrl}/quizzes/fc/audio/mario.mp3`,
      `${baseUrl}/quizzes/fc/audio/antiphase_HC_I.mp3`,
      `${baseUrl}/quizzes/fc/audio/antiphase_HC_O.mp3`,
      `${baseUrl}/quizzes/fc/audio/antiphase_HC_S.mp3`,
    ];

    var imagePreload = [
      `${baseUrl}/quizzes/fc/img/baby.jpg`,
      `${baseUrl}/quizzes/fc/img/adult.jpg`,
      `${baseUrl}/quizzes/fc/img/white.jpg`,
      `${baseUrl}/quizzes/fc/img/incorrect.jpg`,
      `${baseUrl}/quizzes/fc/img/fj_hands_animate.gif`
    ];

    timeline.push(
      welcome,
      intro,
    );

    if (mobile) {
      //do nothin'
    } else {
      timeline.push(
        whichHands
      )
    };

    timeline.push(
      ready,
      trainInfo1B,
      reTrain1B,
      trainInfo1A,
      reTrain1A,
      introTest,
      songTest,
      //continueLogic1, // do not add for now!
      transition,
      musicxp,
      // muppet items
      musicTalent,
      musicListenPleasure,
      musicPleasure,
      singingChoir,
      // end muppet items
      demog,
      email,
      social
    );

    api.checkTimeline(timeline);

    options.targetElement.focus();

    jsPsych.init({
      timeline: timeline,
      preload_audio: audioPreload,
      preload_images: imagePreload,
      use_webaudio: true,
      display_element: options.targetElement,
      on_trial_finish: function(data) {
        //api.saveDataOnFinish(data);
        options.targetElement.focus();

        // Reset to top of page
        window.scrollTo(0,0)
      }
    });
    }

/* eslint-disable max-len */
