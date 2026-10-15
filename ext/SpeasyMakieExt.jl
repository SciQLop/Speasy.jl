module SpeasyMakieExt
using Makie
using Dates
import Makie: convert_arguments
import Makie.SpecApi as S
import Speasy: SpeasyVariable, columns, times, tdimnum
import Speasy: speasyplot, speasyplot!

"""Compatibility with Makie"""
_times(obj::SpeasyVariable) = DateTime.(times(obj))
# One row per component, whichever the layout.
_rows(obj::SpeasyVariable) = tdimnum(obj) == 1 ? transpose(parent(obj)) : parent(obj)

convert_arguments(P::PointBased, obj::SpeasyVariable, i::Integer) =
    convert_arguments(P, _times(obj), _rows(obj)[i, :])
convert_arguments(P::Type{<:Series}, obj::SpeasyVariable) =
    convert_arguments(P, _times(obj), _rows(obj))

@recipe(SpeasyPlot, var) do scene
    Theme()
end

function Makie.plot!(p::SpeasyPlot)
    var = p[1][]
    labels = columns(var)
    if length(labels) > 1
        series!(p, _times(var), _rows(var); labels = string.(labels))
    else
        lines!(p, _times(var), vec(parent(var)))
    end
    return p
end

Makie.get_plots(p::SpeasyPlot) = p.plots[1].plots

Makie.plot!(p::SpeasyVariable) = speasyplot!(p)
Makie.plot(p::SpeasyVariable) = speasyplot(p)

end