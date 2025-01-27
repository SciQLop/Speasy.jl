module MakieExt
using Makie
import Makie: convert_arguments
import Makie.SpecApi as S
import Speasy: SpeasyVariable
import Speasy: speasyplot, speasyplot!

convert_arguments(P::PointBased, obj::SpeasyVariable, i::Integer) =
    convert_arguments(P, obj.time, obj.values[:, i])
convert_arguments(P::Type{<:Series}, obj::SpeasyVariable) =
    convert_arguments(P, obj.time, obj.values')

@recipe(SpeasyPlot, var) do scene
    Theme()
end

function Makie.plot!(p::SpeasyPlot)
    var = p[1][]
    if length(var.columns) > 1
        labels = string.(var.columns)
        series!(p, var.time, var.values'; labels)
    else
        lines!(p, var.time, var.values)
    end
    return p
end

Makie.get_plots(p::SpeasyPlot) = p.plots[1].plots

Makie.plot!(p::SpeasyVariable) = speasyplot!(p)
Makie.plot(p::SpeasyVariable) = speasyplot(p)

end