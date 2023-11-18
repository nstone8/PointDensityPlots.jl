module PointDensityPlots

using RecipesBase

"""
```julia
pointdensity(x,y;binradius=0.01)
```
Create a scatter plot where the data points are colored based on their proximity to
other points. `binradius` is the normalized distance used when judging proximity.
"""
function pointdensity end

@shorthands pointdensity
@recipe function pointdensity(::Type{Val{:pointdensity}}, ox, oy, oz;xscale=:identity,yscale=:identity,binradius = 0.01)
    @assert all(size(ox) .== size(oy))
    scales=Dict(:identity => (a) -> a,
                :ln => log,
                :log2 => log2,
                :log10 => log10,
                :asinh => asinh,
                :sqrt => sqrt)

    #do our colors based on the scaled data
    xscaled=scales[xscale].(ox)
    yscaled=scales[xscale].(oy)
    
    rangex = maximum(xscaled) - minimum(xscaled)
    rangey = maximum(yscaled) - minimum(yscaled)
    
    densitycounts = map(1:length(ox)) do i
        this_x = xscaled[i]
        this_y = yscaled[i]
        xdist = (this_x .- xscaled)/rangex
        ydist = (this_y .- yscaled)/rangey
        dist = sqrt.(xdist.^2 + ydist.^2)
        dc = sum(dist) do d
            (d < binradius) ? 1 : 0
        end
        return dc
    end
    seriestype := :scatter
    xscale := xscale
    yscale := yscale
    marker_z := densitycounts
    markerstrokewidth --> 0
    markersize --> .5
    legend --> false
    colorbar --> false
    x := ox
    y := oy
    ()
end

end # module PointDensityPlots
