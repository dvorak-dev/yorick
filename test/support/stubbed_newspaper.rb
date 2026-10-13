require 'open-uri'

module StubbedNewspaper
  def with_page(html)
    requested_urls = []
    original_open = URI.method(:open)
    URI.define_singleton_method(:open) do |*args|
      requested_urls << args.first
      StringIO.new(html)
    end
    yield requested_urls
  ensure
    URI.define_singleton_method(:open, original_open)
  end

  def two_notice_v2_html
    <<-HTML
      <div class="grid_10 funebres">
        <ul>
          <li class="c">JOHN DOE<br><span>(Q.E.P.D.) Falleció el 30/06/2025.- Su esposa: Jane Doe; sus hijos: John Jr. y Jane Jr. participan su fallecimiento.</span></li>
          <li class="c">JANE SMITH<br><span>(Q.E.P.D.) Falleció el 29/06/2025.- Sus hijos: Tom y Jerry participan su fallecimiento.</span></li>
        </ul>
      </div>
    HTML
  end

  def one_notice_v2_html
    <<-HTML
      <div class="grid_10 funebres">
        <ul>
          <li class="c">JOHN DOE<br><span>(Q.E.P.D.) Falleció el 30/06/2025.- Su esposa: Jane Doe; sus hijos: John Jr. y Jane Jr. participan su fallecimiento.</span></li>
        </ul>
      </div>
    HTML
  end

  def empty_v2_html
    <<-HTML
      <div class="grid_10 funebres">
        <ul>
        </ul>
      </div>
    HTML
  end

  def two_notice_v3_html
    <<-HTML
      <ul class="funeral-names"><li>JOHN DOE</li><li>JANE SMITH</li></ul>
      <h2 class="section-title">SEPELIOS</h2>
      <article class="notice">
        <h3><span class="rs" title="Cruz"><svg><path d="M0 0"/></svg></span>JOHN DOE</h3>
        <p> (Q.E.P.D.) First notice.</p>
      </article>
      <article class="notice">
        <h3><span class="rs" title="Estrella de David"><svg><path d="M0 0"/></svg></span>JOHN DOE</h3>
        <p> (Q.E.P.D.) Second notice.</p>
      </article>
    HTML
  end

  def summary_only_html
    <<-HTML
      <ul class="funeral-names"><li>JOHN DOE</li></ul>
      <h2 class="section-title">SEPELIOS</h2>
    HTML
  end
end
