require 'json'
require 'set'
p = JSON.load(File.read("var/dump/app1550152/people.json"))
d = JSON.load(File.read("var/dump/app1550152/pages.json"));

def levenshtein_distance(s, t)
  m = s.length
  n = t.length
  return m if n == 0
  return n if m == 0
  d = Array.new(m+1) {Array.new(n+1)}

  (0..m).each {|i| d[i][0] = i}
  (0..n).each {|j| d[0][j] = j}
  (1..n).each do |j|
    (1..m).each do |i|
      d[i][j] = if s[i-1] == t[j-1]  # adjust index into string
                  d[i-1][j-1]       # no operation required
                else
                  [ d[i-1][j]+1,    # deletion
                    d[i][j-1]+1,    # insertion
                    d[i-1][j-1]+1,  # substitution
                  ].min
                end
    end
  end
  d[m][n]
end

x = Hash[p.map{|subject|
  authors = if (page = (d.detect{|s| s["_id"] == subject["page_id"]}||{"versions"=>[{}]})["versions"].first) && page["author_name"]
    a = page["author_name"].split(/(und|,)+/).map do |name|
      clean = name.gsub(/[^\w]/, "")
      next nil if clean.empty?
      scores = p.map{|x| [x, levenshtein_distance(x["name"], clean)]}.sort_by{|x|x.last}
      candidate = scores.first
      next nil if candidate.last > 5
      candidate.first["uid"]
    end.compact
    s = Set.new(a)
    s.add(page["author_id"])
    s.to_a
  else
    []
  end

  print '.'

  [subject["uid"], authors]}]

puts
puts JSON.dump(x)
