require 'csv'
require 'pry'
require 'json'

# Merge dino files and extract based on user input
class Dinodex
  attr_accessor :q_text, :hdr_name, :user_req
  WGHT_LIMIT = 4000

  def initialize(file_arry)
    @alldinos = []
    file_arry.each do |file|
      csv = CSV.read(file, headers: true, header_converters: :downcase)
      csv.by_row!
      csv.each do |row|
        dino_temp = row.to_hash
        dino_temp['carnivore'] = 'Carnivore' if dino_temp['carnivore'] == 'Yes'
        @alldinos << dino_temp
      end
    end
    fix_value_hdr
  end

  def fix_value_hdr
    hdr_map = { 'weight_in_lbs' => 'weight', 'genus' => 'name', 'carnivore' => 'diet' }
    @alldinos.each do |dinos|
      dinos.keys.each { |k| dinos[hdr_map[k]] = dinos.delete(k) if hdr_map[k] }
    end
  end

  def grab_dinos(q_text, hdr_name)
    match_dinos = []
    @alldinos.each do |dino|
      hdr_val = dino[hdr_name] unless dino[hdr_name].nil?
      if q_text == 'CARNIVORE'
        match_dinos << dino['name'] if dino_diet?(hdr_val)
      elsif q_text == 'BIG'
        match_dinos << dino['name'] if hdr_val.to_i > WGHT_LIMIT
      elsif q_text == 'SMALL'
        match_dinos << dino['name'] if hdr_val.to_i < WGHT_LIMIT
      elsif hdr_name == 'period' && (dino['period'].downcase.include? q_text)
        match_dinos << dino['name']
      elsif q_text == 'BIPED' || q_text == 'QUADRUPED'
        match_dinos << dino['name'] if (hdr_val.casecmp(q_text) == 0)
      elsif q_text == 'INFO BY NAME'
        each_dino hdr_name
        break
      end
    end
    print_dinos match_dinos
  end

  def print_dinos(dino_output)
    dino_output.each do |dino_out|
      puts dino_out
    end
  end

  def dino_diet?(header_val)
    carni_arry = %w(carnivore insectivore piscivore)
    carni_arry.include? header_val.downcase
  end

  def each_dino(user_req)
    @alldinos.each do |dino_d|
      dinotemp = dino_d['name']
      if (dinotemp.casecmp(user_req) == 0)
        print("************************************************\n")
        dino_d.each { |k, v| print k.upcase, ":\t", v, "\n" unless v.nil? }
        print("************************************************\n")
      elsif user_req.upcase == 'ALL'
        dino_d.each { |k, v| print k.upcase, ":\t", v, "\n" unless v.nil? }
        print("************************************************\n")
      end
    end
  end

  def convert_json
    json_file = File.new('dinos.json', 'w')
    json_file.puts @alldinos.to_json
    json_file.close
  end
end

array_csv = ['dinodex.csv', 'african_dinosaur_export.csv']
my_dino  = Dinodex.new(array_csv)
print 'Enter one or more comma separated choices (Biped, Quadruped, Carnivore, period, big, small, info by name):'
userq = gets.chomp
userinput = userq.split(',')
userinput.each do |val|
  uinput = val.strip
  q_text = uinput.upcase
  case q_text
    when 'BIPED', 'QUADRUPED'
      puts "Dinosaurs that were #{q_text} are: \n"
      my_dino.grab_dinos q_text, 'walking'
    when 'CARNIVORE'
      puts "Dinosaurs that were carnivores are: \n"
      my_dino.grab_dinos q_text, 'diet'
    when 'PERIOD'
      print "Enter the period from the choice of - (Cretaceous, Permian, Jurassic, Oxfordian, Triassic, Albian): \n"
      user_period = gets.chomp
      puts "List of all Dinosaurs for the period of #{user_period} are: \n"
      my_dino.grab_dinos user_period.downcase, 'period'
    when 'BIG', 'SMALL'
      puts "Dinosaurs that were #{q_text} are :\n"
      my_dino.grab_dinos q_text, 'weight'
    when 'INFO BY NAME'
      print "Enter the name of the dinosaur to print the facts or type all to get information on all Dinosaurs: \n"
      user_dino = gets.chomp
      my_dino.grab_dinos q_text, user_dino
    else
      puts 'No selection made'
  end
end
my_dino.convert_json
