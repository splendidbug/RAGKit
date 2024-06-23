## TODO: Make multiple dispatch for the following function to remove if-else
"""
    parse_robots_txt!(robots_txt::String)

Parses the robots.txt string and returns rules along with the URLs on Sitemap

# Arguments
- `robots_txt`: robots.txt as a string
"""
function parse_robots_txt!(robots_txt::String)
    rules = Dict{String,Dict{String,Vector{String}}}()
    current_user_agent = ""
    sitemap_urls = Vector{AbstractString}()

    for line in split(robots_txt, '\n')
        line = strip(line)
        if startswith(line, "User-agent:")
            current_user_agent = strip(split(line, ":")[2])
            if !haskey(rules, current_user_agent)
                rules[current_user_agent] = Dict("Disallow" => Vector{String}(), "Allow" => Vector{String}())
            end
        elseif startswith(line, "Disallow:")
            disallow_path = strip(split(line, ":")[2])
            if current_user_agent != "" && disallow_path != ""
                push!(rules[current_user_agent]["Disallow"], disallow_path)
            end
        elseif startswith(line, "Allow:")
            allow_path = strip(split(line, ":")[2])
            if current_user_agent != "" && allow_path != ""
                push!(rules[current_user_agent]["Allow"], allow_path)
            end
        elseif startswith(line, "Sitemap:")
            url = strip(split(line, ":")[2])
            push!(sitemap_urls, url)
        end

    end
    return rules, sitemap_urls
end


"""
    check_robots_txt(user_agent::AbstractString,
        url::AbstractString)

Checks the robots.txt of a URL and returns a boolean representing if `user_agent` is allowed to crawl the input url

# Arguments
- `user_agent`: user agent attempting to crawl the webpage
- `url`: input URL string
"""
function check_robots_txt(user_agent::AbstractString,
    url::AbstractString)

    ## TODO: Make a cache of rules for a quick lookup
    # if (haskey(restricted_urls, url))
    #     if (in(path, restricted_urls[url]))
    #         println("Not allowed to crawl $url")
    #         return false
    #     else
    #         return true
    #     end
    # end

    URI = URIs.URI(url)
    path = URI.path

    robots_URL = string(URI.scheme, "://", URI.host, "/robots.txt")
    sitemap_urls = Vector{AbstractString}()
    try
        response = HTTP.get(robots_URL)
        robots_txt = String(response.body)
        rules, sitemap_urls = parse_robots_txt!(robots_txt)
        user_agents = [user_agent, "*"]
        for ua in user_agents
            if haskey(rules, ua)
                allow_rules = rules[ua]["Allow"]
                disallow_rules = rules[ua]["Disallow"]

                for allow_rule in allow_rules
                    if startswith(path, allow_rule)
                        return true, sitemap_urls
                    end
                end

                for disallow_rule in disallow_rules
                    if startswith(path, disallow_rule)
                        @warn "Not allowed to crawl $url"
                        return false, sitemap_urls
                    end
                end
            end
        end
        return true, sitemap_urls
    catch
        @info "robots.txt unavailable for $url"
        return true, sitemap_urls
    end
end

"""
    get_base_url(url::AbstractString)

Extracts the base url.

# Arguments
- `url`: The url string of which, the base url needs to be extracted
"""
function get_base_url(url::AbstractString)

    parsed_url = URIs.URI(url)
    base_url = string(parsed_url.scheme, "://", parsed_url.host,
        parsed_url.port != nothing ? "" * string(parsed_url.port) : "", parsed_url.path)
    return base_url
end


"""
    process_hostname(url::AbstractString)

Returns the hostname of an input URL

# Arguments
- `url`: URL string
"""
function process_hostname(url::AbstractString)
    URI = URIs.URI(url)
    hostname = String(URI.host)
    return hostname
end


"""
    process_hostname(url::AbstractString, hostname_dict::Dict{AbstractString,Vector{AbstractString}})

Adds the `url` to it's hostname in `hostname_dict`

# Arguments
- `url`: URL string
- `hostname_dict`: Dict with key being hostname and value being a vector of URLs
"""
function process_hostname!(url::AbstractString, hostname_dict::Dict{AbstractString,Vector{AbstractString}})
    hostname = process_hostname(url)

    # Add the URL to the dictionary under its hostname
    if haskey(hostname_dict, hostname)
        push!(hostname_dict[hostname], url)
    else
        hostname_dict[hostname] = [url]
    end
end


"""
    crawl(input_urls::Vector{<:AbstractString})

Crawls on the input URLs and returns a `hostname_url_dict` which is a dictionary with key being hostnames and the values being the URLs

# Arguments
- `input_urls`: A vector of input URLs
"""
function crawl(input_urls::Vector{<:AbstractString})

    url_queue = Vector{AbstractString}(input_urls)
    visited_url_set = Set{AbstractString}()
    hostname_url_dict = Dict{AbstractString,Vector{AbstractString}}()
    sitemap_urls = Vector{AbstractString}()

    # TODO: Add parallel processing for URLs
    while !isempty(url_queue)
        url = url_queue[1]
        popfirst!(url_queue)
        base_url = get_base_url(url)

        if !in(base_url, visited_url_set)
            push!(visited_url_set, base_url)
            crawlable, sitemap_urls = check_robots_txt("*", base_url)
            append!(url_queue, sitemap_urls)
            if crawlable
                try
                    get_urls!(base_url, url_queue)
                    process_hostname!(url, hostname_url_dict)
                catch
                    @error "Bad URL: $base_url"
                end
            end
        end
    end

    return hostname_url_dict

end
