module SpeasyMakieExt
using Makie
using Dates
import Makie: convert_arguments
import Makie.SpecApi as S
import Speasy: SpeasyVariable
import Speasy: speasyplot, speasyplot!

"""Compatibility with Makie"""
_times(obj::SpeasyVariable) = DateTime.(obj.time)

convert_arguments(P::PointBased, obj::SpeasyVariable, i::Integer) =
    convert_arguments(P, _times(obj), obj.values[:, i])
convert_arguments(P::Type{<:Series}, obj::SpeasyVariable) =
    convert_arguments(P, _times(obj), obj.values')

@recipe(SpeasyPlot, var) do scene
    Theme()
end

function Makie.plot!(p::SpeasyPlot)
    var = p[1][]
    if length(var.columns) > 1
        labels = string.(var.columns)
        series!(p, _times(var), var.values'; labels)
    else
        lines!(p, _times(var), var.values)
    end
    return p
end

Makie.get_plots(p::SpeasyPlot) = p.plots[1].plots

Makie.plot!(p::SpeasyVariable) = speasyplot!(p)
Makie.plot(p::SpeasyVariable) = speasyplot(p)

end