"Finds duplicates in a list of chunks using SHA-256 hash. Returns a bit vector of the same length as the input list, where `true` indicates a duplicate (second instance of the same text)."
function find_duplicates(chunks::AbstractVector{<:AbstractString})
    # hash the chunks for easier search
    hashed_chunks = bytes2hex.(sha256.(chunks))
    sorted_indices = sortperm(hashed_chunks)  # Sort indices based on hashed values

    duplicates = falses(length(chunks))
    prev_hash = ""  # Initialize with an empty string to ensure the first comparison fails

    for idx in sorted_indices
        current_hash = hashed_chunks[idx]
        # Check if current hash matches the previous one, indicating a duplicate
        if current_hash == prev_hash
            duplicates[idx] = true  # Mark as duplicate
        else
            prev_hash = current_hash  # Update previous hash for the next iteration
        end
    end

    return duplicates
end

"Removes chunks that are duplicated in the input list of chunks and their corresponding sources."
function remove_duplicates(chunks::AbstractVector{<:AbstractString}, sources::AbstractVector{<:AbstractString})
    idxs = find_duplicates(chunks)
    return chunks[.!idxs], sources[.!idxs]
end

"Removes chunks that are shorter than a specified length (`min_length`) from the input list of chunks and their corresponding sources."
function remove_short_chunks(chunks::AbstractVector{<:AbstractString}, sources::AbstractVector{<:AbstractString}; min_length::Int=40, skip_code::Bool=true)
    idx = if skip_code
        ## Keep short chunks if they contain code (might be combined with some preceding/suceeeding text)
        findall(x -> length(x) >= min_length || occursin("```", x), chunks)
    else
        findall(x -> length(x) >= min_length, chunks)
    end
    return chunks[idx], sources[idx]
end


function replace_local_paths(sources::AbstractVector{<:AbstractString}, paths::AbstractVector{<:AbstractString}, websites::AbstractVector{<:AbstractString})
    @assert length(paths) == length(websites) "Length of `paths` must match length of `websites`"
    replacement_pairs = paths .=> websites
    output = map(x -> replace(x, replacement_pairs...), sources)
end


"Post-processes the input list of chunks and their corresponding sources by removing short chunks and duplicates."
function postprocess_chunks(chunks::AbstractVector{<:AbstractString}, sources::AbstractVector{<:AbstractString}; min_length::Int=40, skip_code::Bool=true,
    paths::Union{Nothing,AbstractVector{<:AbstractString}}=nothing, websites::Union{Nothing,AbstractVector{<:AbstractString}}=nothing)
    len_ = length(chunks)
    chunks, sources = remove_short_chunks(chunks, sources; min_length, skip_code)
    @info "Removed $(len_ - length(chunks)) short chunks"

    len_ = length(chunks)
    chunks, sources = remove_duplicates(chunks, sources)
    @info "Removed $(len_ - length(chunks)) duplicate chunks"

    ## Renaming sources
    if !isnothing(paths) && !isnothing(websites)
        sources = replace_local_paths(sources, paths, websites)
        @info "Replaced local paths with websites"
    end

    return chunks, sources


end