module PointDensityPlots

using RecipesBase, Logicle, LaTeXStrings

"""
```julia
logiclescale(data)
```
Scale data using `Logicle` and generate our ticks
"""
function logiclescale(data,ls,excludeticks)
    #build the scale if we weren't given it
    ls = isnothing(ls) ? LogicleScale(data) : ls
    #scale the data
    scaled_data = ls.(data)

    #decide what ticks we're going to want
    dmin = minimum(data)
    if iszero(dmin)
        #first tick a little below our minimum
        minpower = -1
    else
        signdmin = sign(dmin)
        #gotta deal with dmin being negative
        minpower = signdmin*floor(Int,signdmin*dmin |> log10)
    end
    dmax = maximum(data)
    if iszero(dmax)
        #last tick a little above our maximum
        maxpower = 1
    else
        #don't think our maximum values will ever be negative, but might as well...
        signdmax = sign(dmax)
        maxpower = signdmax*ceil(Int,signdmax*dmax |> log10)
    end
    tickvec = []
    for power in minpower:maxpower
        if iszero(power)
            push!(tickvec,[0,L"0"])
        end
        
        push!(tickvec,[10^power,L"10^%$(Int(power))"])
        
        minorvals = collect(1:9)
        if power<0
            #need to count up
            power +=1
            minorvals = reverse(minorvals)
        end
        for mv in minorvals
            push!(tickvec,[mv*10^power,""])
        end
    end
    #tickvec is now a vector of 2-vectors. The first entry in each sub vector is the unscaled
    #value where we want a tick and the second entry is the label

    #filter ticks which are greater than our maximum value or less than our minimum value
    filter!(tickvec) do tv
        dmin <= tv[1] <= dmax
    end
    #now scale the values
    scaledtickvals = map(tickvec) do tv
        ls(tv[1])
    end
    #and collect the labels into a single vector. If the value for this tick is in `excludeticks`
    #remove the label
    scaledticklabs = map(tickvec) do tv
        any(tv[1] .≈ 10 .^ float.(excludeticks)) ? "" : tv[2]
    end
    (scaled_data,(scaledtickvals,scaledticklabs))
end

"""
```julia
pointdensity(x,y;binradius=0.05,excludeticksx=[],excludeticksy=[])
```
Create a scatter plot where the data points are colored based on their proximity to
other points. `binradius` is the normalized distance used when judging proximity.
The `excludeticks` plot attributes can be used to selectively remove labels from
major ticks on `:logicle` axes. In addition to passing `:logicle` to the `xaxis` or
`yaxis` plot attributes, one can also pass a `LogicleScale` to the `:logiclescalex`
or `:logiclescaley` attributes to set an explicit transformation.
"""
function pointdensity end

@shorthands pointdensity
@recipe function pointdensity(::Type{Val{:pointdensity}}, ox, oy, oz)
    xscale --> :logicle
    yscale --> :logicle

    logiclescalex --> nothing
    logiclescaley --> nothing

    if plotattributes[:logiclescalex] isa LogicleScale
        :xscale := plotattributes[:logiclescalex]
    end
    
    if plotattributes[:logiclescaley] isa LogicleScale
        :yscale := plotattributes[:logiclescaley]
    end

    binradius --> 0.05
    excludeticksx --> []
    excludeticksy --> []
    @assert all(size(ox) .== size(oy))
    scales=Dict(:identity => (a) -> a,
                :ln => log,
                :log2 => log2,
                :log10 => log10,
                :asinh => asinh,
                :sqrt => sqrt)
    
    #do our colors based on the scaled data
    if (plotattributes[:xscale] != :logicle) && !(plotattributes[:xscale] isa LogicleScale)
        xscaled=scales[plotattributes[:xscale]].(ox)
        x := ox
    else
        lsx = (plotattributes[:xscale] isa LogicleScale) ? plotattributes[:xscale] : nothing
        (xscaled, xlogicleticks) = logiclescale(ox,lsx,plotattributes[:excludeticksx])
        x := xscaled
        xticks := xlogicleticks
        xscale := :identity
        xlims := (0,1)
    end

    if (plotattributes[:yscale] != :logicle) && !(plotattributes[:yscale] isa LogicleScale)
        yscaled=scales[plotattributes[:yscale]].(oy)
        y := oy
    else
        lsy = (plotattributes[:yscale] isa LogicleScale) ? plotattributes[:yscale] : nothing
        (yscaled, ylogicleticks) = logiclescale(oy,lsy,plotattributes[:excludeticksy])
        y := yscaled
        yticks := ylogicleticks
        yscale := :identity
        ylims := (0,1)
    end
    
    rangex = maximum(xscaled) - minimum(xscaled)
    rangey = maximum(yscaled) - minimum(yscaled)
    
    densitycounts = map(1:length(ox)) do i
        this_x = xscaled[i]
        this_y = yscaled[i]
        xdist = (this_x .- xscaled)/rangex
        ydist = (this_y .- yscaled)/rangey
        dist = sqrt.(xdist.^2 + ydist.^2)
        dc = sum(dist) do d
            (d < plotattributes[:binradius]) ? 1 : 0
        end
        return dc
    end
    seriestype := :scatter
    marker_z := densitycounts
    markerstrokewidth --> 0
    markersize --> .5
    legend --> false
    colorbar --> false
    ()
end

end # module PointDensityPlots
