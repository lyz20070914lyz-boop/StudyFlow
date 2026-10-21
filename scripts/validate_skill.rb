#!/usr/bin/env ruby
# Static release checks only; this does not run a model or measure learning.
require 'yaml'
require 'csv'
require 'pathname'

root = File.expand_path('..', __dir__)
def ensure_valid(condition, message)
  abort("FAIL: #{message}") unless condition
end

metadata_text = File.read(File.join(root, 'SKILL.md'), encoding: 'UTF-8')
match = metadata_text.match(/\A---\n(.*?)\n---(?:\n|\z)/m)
ensure_valid(match, 'SKILL.md must begin with YAML frontmatter')
metadata = YAML.safe_load(match[1])
ensure_valid(metadata.is_a?(Hash), 'frontmatter must be a mapping')
ensure_valid(metadata.keys.sort == %w[description name], 'unexpected frontmatter fields')
ensure_valid(metadata['name'] == 'study-flow', 'skill name must be study-flow')
ensure_valid(metadata['description'].is_a?(String) && (1..1024).cover?(metadata['description'].length), 'invalid skill description')

ui = YAML.safe_load(File.read(File.join(root, 'agents/openai.yaml'), encoding: 'UTF-8'))
ensure_valid(ui.dig('policy', 'allow_implicit_invocation') == true, 'implicit invocation must stay enabled')
ensure_valid(ui.dig('interface', 'display_name') == 'StudyFlow', 'invalid display name')
ensure_valid((25..64).cover?(ui.dig('interface', 'short_description').to_s.length), 'UI description must have 25-64 characters')
ensure_valid(ui.dig('interface', 'default_prompt').to_s.include?('$study-flow'), 'default prompt must name the skill')

allowed_roots = %w[SKILL.md README.md README.en.md LICENSE CHANGELOG.md .gitignore agents references templates evals scripts .git]
ensure_valid((Dir.children(root) - allowed_roots).empty?, 'unexpected root files; review the release scope')

files = Dir.glob(File.join(root, '**', '*'), File::FNM_DOTMATCH).select do |path|
  File.file?(path) && !Pathname.new(path).relative_path_from(Pathname.new(root)).each_filename.include?('.git')
end
files.each do |path|
  ensure_valid(!File.symlink?(path), 'release must not contain file symlinks')
  content = File.read(path, encoding: 'UTF-8')
  ensure_valid(content.valid_encoding?, "non-UTF-8 file: #{File.basename(path)}")
  ensure_valid(!content.match?(%r{/Users/[A-Za-z0-9_.-]+/|wxid_[a-zA-Z0-9_]+|[A-Za-z0-9._%+-]+@gmail\.com}), "personal data marker in #{File.basename(path)}")
  next unless File.extname(path) == '.md'
  ensure_valid(!content.match?(/\[TODO:/), "unfinished scaffold in #{File.basename(path)}")
  content.scan(/\]\(([^)]+)\)/).flatten.each do |target|
    next if target.start_with?('https://', 'http://', '#')
    resolved = File.expand_path(target.split('#', 2).first, File.dirname(path))
    ensure_valid(resolved.start_with?(root + File::SEPARATOR) && File.file?(resolved), "broken or out-of-scope link: #{target}")
  end
end

cases = CSV.read(File.join(root, 'evals/trigger-prompts.csv'), headers: true, encoding: 'UTF-8')
ensure_valid(cases.headers == %w[id should_trigger route prompt expected_behavior], 'unexpected evaluation columns')
ensure_valid(!cases.empty? && cases.map { |row| row['id'] }.uniq.length == cases.length, 'empty or duplicate evaluation IDs')
routes = %w[planning understanding memory-and-testing self-regulation exams course-cycle applied-skills session-progress explicit continuity capability none]
cases.each do |row|
  ensure_valid(row.fields.length == 5 && row.fields.all? { |field| field && !field.strip.empty? }, "incomplete case: #{row['id']}")
  ensure_valid(%w[true false].include?(row['should_trigger']) && routes.include?(row['route']), "invalid case: #{row['id']}")
  ensure_valid(row['route'] == 'none', "negative case must use none: #{row['id']}") if row['should_trigger'] == 'false'
end
declared_count = File.read(File.join(root, 'README.md')).match(/包含 (\d+) 个场景/)
ensure_valid(declared_count && declared_count[1].to_i == cases.length, 'README case count differs from CSV')
english_count = File.read(File.join(root, 'README.en.md')).match(/contains (\d+) scenarios/)
ensure_valid(english_count && english_count[1].to_i == cases.length, 'English README case count differs from CSV')
paired = cases.select { |row| row['id'].start_with?('bi-') }.group_by { |row| row['id'].sub(/-(zh|en)\z/, '') }
ensure_valid(paired.length >= 12 && paired.values.all? { |rows| rows.map { |row| row['id'].split('-').last }.sort == %w[en zh] }, 'incomplete bilingual case pairs')
ensure_valid(File.file?(File.join(root, 'templates/progress.md')), 'missing progress template')
puts "PASS: metadata, YAML, release scope, internal links, #{cases.length} evaluation cases"
puts 'Model behavior and learning outcomes: not tested by this script.'
