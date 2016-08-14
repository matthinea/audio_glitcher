/*develpment objectives:
     role of midi input: instead of a simple gate, let a knob control /rate of glitches/. so, at 0, no glitching, at 0.5 glitching every 4s, at 1.0 glitching on average every 0.4s.
         *logic: code a dust.kr as a trigger, and the rate of the dust.kr will be input from a bus controlled by midi cc

code to do:
*test
		//use nested maxs and mins to eliminate middle band?
		//use nested LFOs to make 'random'-seeming 'holds'
*/

s.boot;

~bufPianoSwells = Buffer.read(s, "/Users/matthewhinea/supercollider/Piano Swells.aif"); //use your path, obviously
//synth
(
SynthDef(\LFO_glitch,
	{
		|trig = 0, rate = 1, mul = 1|
		var out, env, array, cycle, bufnum, levels, times, which, selectTrig;

		bufnum = ~bufPianoSwells.bufnum;
		array = [Line.ar(1,1,inf,1), //normal rate (plays uninterrupted sound file)
			Line.ar(1,1,inf,1)
			* LFNoise0.ar( //rate of change
				LFNoise0.ar( //rate of change of rate of change
					LFNoise1.kr(18), //rate of change of rate of change of rate of change
					3, 6),
				0.8, 1.0)
			+ WhiteNoise.ar(0.3) //additional static effect
		];
		cycle = array.size * 0.5;
		cycle.postln;
		which = (LFNoise0.kr(12, cycle, cycle/6)
			* Saw.kr(1/8.612857, 2.6, 0.6) //increase likelihood of glitches on piano strikes
			* (1 + max((LFSaw.kr(1/8.612857, 1.4, mul:10.5)-4), 0)) //some chance of glitch on the tail of fadeouts
			* XLine.kr(0.001, 1.25, ~bufPianoSwells.duration) //more glitches near end of file
		).scope.poll(1);
		out = BufRd.ar(
			2,
			bufnum,
			Phasor.ar(trig,
				BufRateScale.kr(bufnum) * Select.ar(which, array) * rate,
				0,
				BufFrames.kr(bufnum)- 2
			), 0
		);
		out = out * mul;
		out = FreeVerb.ar(out, //simple reverb
			mix: 0.23,
			room: 0.6,
			damp: 0.3,
			mul: 1
		);

		Out.ar(0, out);
}).play
)


//simple play

x = Synth(\LFO_glitch);
x.free;

//in a Task, for more accurate sample looping
(
t = Task({
	inf.do{
		x = Synth(\LFO_glitch);
		60.wait;
		x.free;

		y = Synth(\LFO_glitch);
		60.wait;
		y.free;
	}
});
)
t.play;
t.yield;



//to make it so one synth continues where the other one left off: ??
           //tests
(
{
LFNoise0.ar( //change rate
				LFNoise0.ar( //change rate of rate of change
					LFNoise1.kr(18), //change rate of rate of change of rate of change
					3, 6),
	1, 0.8)}.scope;
)



{LFSaw.kr(1.0,0.0,1,1)}.plot(10);

//alternate envs:
/*
Env.new(
					[0, 3, 0.2, 2, 1.8, 1.95, 1.7, 2.6, 0.4, 2],
					[0.0755/2, 0.12, 0.15, 0.16, 0.167, 0.169, 0.174, 0.19, 0.225],
					curve: \lin
				)



Env.new(
					[0, 2.5, 2.5, 0.9, 0.9, 1.9, 1.9, 1.85, 1.85, 2.1, 2.1, 1.95, 1.95, 2.4, 2.4, 2.25, 2.25, 1.3, 1.3, 2],
					[1e-4, 0.125, 1e-4, 0.25, 1e-4, 0.07, 1e-4, 0.03, 1e-4, 0.02, 1e-4, 0.1, 1e-4, 0.075, 1e-4, 0.05, 1e-4, 0.25]
				)
*/





//put it in a global variable


(
SynthDef("help-Select",{ arg out=0;

    var a,cycle;
    a = [
            SinOsc.ar,
            Saw.ar,
            Pulse.ar
        ];
    cycle = a.size  * 0.5;
    Out.ar(out,
        Select.ar(LFSaw.kr(1.0,0.0,cycle,cycle),a) * 0.2
    )
}).play;

)





MIDIClient.init;
MIDIIn.connectAll;


(
MIDIdef.cc(\uGenSelector, {
	arg val, num, chan, src;
	[val, num, chan, src].postln; //a good freqshift value is ~0.62
	~uGenSelect.set(val.linlin(0, 127, 0, 1)); //synths we want to affect read in from
}, 22).permanent_(true);
)