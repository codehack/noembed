package Noembed::Source::Wikipedia;

use Web::Scraper;
use List::MoreUtils qw/any/;

use parent 'Noembed::Source';

sub prepare_source {
  my $self = shift;

  $self->{scraper} = scraper {
    process "#firstHeading", title => 'TEXT';
    process "#bodyContent", html => \&_extract_content;
  };
}

sub patterns { 'http://[^\.]+\.wikipedia\.org/wiki/.*' }
sub provider_name { "Wikipedia" }

sub filter {
  my ($self, $body) = @_;
  $self->{scraper}->scrape($body);
}

sub _extract_content {
  my $el = shift;

  my ($image) = $el->look_down(class => "fullImageLink");
  if ($image) {
    my ($img) = $image->find("img");
    if ($img) {
      my $src = $img->attr("src");
      return "<a href=\"$src\" target=\"_blank\"><img src=\"$src\"></a>";
    }
  }

  return _extract_text_content($el);
}

sub _extract_text_content {
  my $el = shift;
  my $output;
  my @children = $el->content_list;

  for my $child (@children) {
    my $tag = $child->tag;

    # stop once we hit the toc or a sub-head
    last if $child->attr("id") eq "toc"
         or $tag eq "h2";

    if (any {$tag eq $_} qw/p ul li/) {

      # fix the links
      for my $a ($child->find("a")) {
        my $href = $a->attr("href");
        $a->attr("target", "_blank");
        $a->attr("href", "http://www.wikipedia.org/$href");
      }

      $output .= $child->as_HTML;
    }
  }

  return "<div class='wikipedia-embed'>$output</div>";
}

1;
