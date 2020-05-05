#!/usr/bin/perl
#
#	https://github.com/jmakino/coronavirus/blob/master/nishiura.cr
#
use strict;
use warnings;
use lib qw(../gsfh);

clop_init(__LINE__, __FILE__, __DIR__, "optionstr")
options=CLOP.new(optionstr,ARGV)
pp! options

def equations(x,a)
  [(a*(1-x[0]-x[1])-1)*x[0], x[0]].to_mathv
end



h = 0.01
steps = (options.tend/h+0.5).to_i



if options.ylog
  setwindow(0, options.tend,options.x0,options.h)
  box(major_y:1, ylog: true)
else
  setwindow(0, options.tend,0,options.h)
  box
end



setcharheight(0.03)
mathtex(0.5, 0.06, "t")
mathtex(0.06, 0.5,
        ["x", "y", "x+y"][options.i])

avals = Array(Float64).new
options.r0.each{|rnot|
  options.rf.each{|rf|
    t=0.0
    x=[options.x0,0.0].to_mathv
    xx = [x[0],x[1], x[0]+x[1]]
    ff = -> (xx : MathVector(Float64), t : Float64){
      r=rnot
      r=rnot*rf if t >= options.tint
      equations(xx, r)
    }
    steps.times{|i|
      tp =t
      xp=xx
      x, t = Integrators.rk2(x,t,h,ff)
      xx = [x[0],x[1], x[0]+x[1]]
      if options.plot_derivative
        xx = ff.call(x,t)
        xx.push xx[0]+xx[1]
      end
      polyline([tp,t],[xp[options.i], xx[options.i]]) 
    }
  }
}

c=gets
