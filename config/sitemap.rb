# For www.eventstaffing.co.uk
SitemapGenerator::Sitemap.default_host = "https://www.eventstaffing.co.uk"
SitemapGenerator::Sitemap.sitemaps_path = "sitemaps/www.eventstaffing.co.uk"
SitemapGenerator::Sitemap.create do

  %w{about join_us privacy events contact register}.each do |page|
    add "/#{page}"
  end

  add "/login", priority: 0.9, changefreq: 'daily'
  add "/events", priority: 0.9, changefreq: 'daily'

end

# For eventstaffing.co.uk
SitemapGenerator::Sitemap.default_host = "https://eventstaffing.co.uk"
SitemapGenerator::Sitemap.sitemaps_path = "sitemaps/eventstaffing.co.uk"
SitemapGenerator::Sitemap.create do
  # Put links creation logic here.
  #
  # The root path '/' and sitemap index file are added automatically for you.
  # Links are added to the Sitemap in the order they are specified.
  #
  # Usage: add(path, options={})
  #        (default options are used if you don't specify)
  #
  # Defaults: :priority => 0.5, :changefreq => 'weekly',
  #           :lastmod => Time.now, :host => default_host
  #
  # Examples:
  #
  # Add '/articles'
  #
  #   add articles_path, :priority => 0.7, :changefreq => 'daily'
  #
  # Add all articles:
  #
  #   Article.find_each do |article|
  #     add article_path(article), :lastmod => article.updated_at
  #   end

  %w{about join_us privacy events login contact register}.each do |page|
    add "/#{page}"
  end

  add "/events", priority: 0.9, changefreq: 'daily'

end

