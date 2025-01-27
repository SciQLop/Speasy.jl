module MakieExt
using Makie
import Makie.SpecApi as S
import Speasy: SpeasyVariable
import Speasy: speasyplot, speasyplot!

function Makie.convert_arguments(P::PointBased, obj::SpeasyVariable)
    return S.Lines(obj.time, obj.values)
end

Makie.convert_arguments(P::Type{<:Series}, obj::SpeasyVariable) = S.Series(obj.time, obj.values')

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