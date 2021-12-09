using Test

for path in readdir(isinteractive() ? pwd() : @__FILE__)
    if isdir(path)
        include(joinpath(path, "test", "runtests.jl"))
    end
end
