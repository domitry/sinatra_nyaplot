require 'sinatra/base'
require 'gsl'
require 'nyaplot'

class NyaplotApp < Sinatra::Base
  enable :sessions

  @@p = {
    a: 1.013,
    b: -0.021,
    c: 0.019,
    d: 0.96,
    e: 0,
    f: 0.01,
    g: 1,
    u: 0.05,
    i: 0.05
  }

  @@ode_func = Proc.new { |t, y, dydt, mu|
    p = @@p
    dydt[0] = (y[0]-p[:a]*y[1])*Math.cos(y[2])-p[:b]*y[1]*Math.sin(y[2])
    dydt[1] = (y[0]+p[:c]*y[1])*Math.sin(y[2])+p[:d]*y[1]*Math.cos(y[2])
    dydt[2] = p[:e] + p[:f]*y[2] + p[:g]*Math.atan(((1-p[:u])*y[1]) / (1-p[:i])*y[0])
  }

  before do
    t = 0
    t1 = 800
    h = 1e-10
    y = GSL::Vector::alloc([0.9, 1, 1])
    solver = GSL::Odeiv::Solver.alloc(GSL::Odeiv::Step::RK8PD, [1e-11, 0.0], @@ode_func, 3)
    mat = []

    while t < t1
      t, h, status = solver.apply(t, t1, h, y)
      break if status != GSL::SUCCESS
      mat.push([y[0],y[1],y[2]])
    end

    mat = mat.transpose

    plot = Nyaplot::Plot.new
    line = plot.add(:line, mat[0], mat[1].map{|v| -v})
    line.stroke_width(1)
    line.color("rgb(123,204,196)")
    @frame = Nyaplot::Frame.new
    @frame.add(plot)
  end

  get '/' do
    @p = @@p
    erb :index
  end

  post '/' do
    @@p.keys().each{|k| @@p[k] = @params[k].to_f}
    @p = @@p
    erb :index
  end
end
