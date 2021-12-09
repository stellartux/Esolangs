using Test
include("../src/PortableMinskyMachineNotation.jl")
using .PortableMinskyMachineNotation

@testset "Standard syntax" begin
    standardmachine = pmmn"""
/* Compiles the core grammar and extensions */
inc_by(0, 88);
inc_by(1, 112);
inc_by(2, 120);
inc_by(3, 34);
output(0);
output(1);
output(2);
output(3);
"""
    @test standardmachine isa Function
    @test standardmachine() == "Wow!"
end

@testset "Extended syntax" begin
    julianmachine = pmmn"""
# supports Julia style syntax too
inc(1, 2)
while dec(1)
    input(0)
    output(0)
end
"""
    @test julianmachine(":D") == ":D"

    chunkybaconmachine = pmmn"""
# or pretend it's Ruby if that's your jam
inc 1, 8
while dec 1
  input 0
  dec 0
  output 0
end
"""
    @test chunkybaconmachine("IBM.:111") == "HAL-9000"
end

@testset "Loading files" begin
    @test load("program.txt")() == "Load programs from files!"
end
