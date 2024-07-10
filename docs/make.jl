using Documenter: Documenter, makedocs, deploydocs
using PkgTemplates: PkgTemplates

makedocs(;
    modules=[PkgTemplates],
    authors="Shreyas Agrawal <48771895+splendidbug@users.noreply.github.com>",
    repo="https://github.com/splendidbug/RAGKit",
    sitename="RAGKit.jl",
    # format=Documenter.HTML(;
    #     repolink="https://github.com/splendidbug/RAGKit",
    #     canonical="https://juliaci.github.io/PkgTemplates.jl",
    #     assets=String[],
    # ),
    pages=[
        "Home" => "index.md",
        "User Guide" => "user.md",
        "Developer Guide" => "developer.md",
        "Migrating To PkgTemplates 0.7+" => "migrating.md",
    ],
)

deploydocs(;
    repo="https://github.com/splendidbug/RAGKit",
)
