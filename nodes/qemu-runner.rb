#!@ruby@/bin/ruby
require 'json'
require 'securerandom'

class QemuRunner
  def initialize(config)
    @config = config
    @virtiofs_daemons = []
  end

  def start
    start_virtiofs
    sleep(1)
    start_qemu
    sleep(1)
    stop_virtiofs
  end

  protected

  attr_reader :config, :virtiofs_daemons

  def start_virtiofs
    config[:'virtio-fs'].each do |name, path|
      pid = Process.fork do
        Process.exec(
          config[:virtiofsd],
          "--socket-path=#{virtiofs_socket_path(name)}",
          '--shared-dir', path,
          '--cache', 'never'
        )
      end

      virtiofs_daemons << pid
    end
  end

  def stop_virtiofs
    virtiofs_daemons.each do |pid|
      Process.kill('TERM', pid)
    end

    virtiofs_daemons.each do |pid|
      Process.wait(pid)
    end
  end

  def start_qemu
    cmd = qemu_command

    pid = Process.fork do
      Process.exec(*cmd)
    end

    Process.wait(pid)
  end

  def qemu_command
    kernel_params = [
      'console=ttyS0',
      "init=#{config[:toplevel]}/init"
    ] + config[:kernelParams]

    [
      "#{config[:qemu]}/bin/qemu-kvm",
      '-name', config[:name],
      '-m', config[:memory].to_s,
      '-cpu', 'host',
      '-smp', "cpus=#{config[:cpus]},cores=#{config[:cpu][:cores]},threads=#{config[:cpu][:threads]},sockets=#{config[:cpu][:sockets]}",
      # "-numa", "node,cpus=0-3,nodeid=0",
      # "-numa", "node,cpus=4-7,nodeid=1",
      # "-numa", "node,cpus=8-11,nodeid=2",
      # "-numa", "node,cpus=12-15,nodeid=3",
      '--no-reboot',
      '-device', 'ahci,id=ahci',
      '-drive', "index=0,id=drive1,file=#{config[:squashfs]},readonly,media=cdrom,format=raw,if=virtio",
      '-kernel', config[:kernel],
      '-initrd', config[:initrd],
      '-append', kernel_params.join(' ').to_s,
      '-nographic',

      # Bridged network
      '-device', "virtio-net,netdev=net1,mac=#{gen_mac_address}",
      '-netdev', 'bridge,id=net1,br=virbr0'
    ] + qemu_disk_options + qemu_virtiofs_options
  end

  def qemu_disk_options
    ret = []

    config[:disks].each_with_index do |disk, i|
      ret << '-drive' << "id=disk#{i},file=#{disk[:device]},if=none,format=raw"
      ret << '-device' << "ide-hd,drive=disk#{i},bus=ahci.#{i}"
    end

    ret
  end

  def qemu_virtiofs_options
    ret = []

    config[:'virtio-fs'].each_with_index do |fs, i|
      name, = fs
      ret << '-chardev' << "socket,id=char#{i},path=#{virtiofs_socket_path(name)}"
      ret << '-device' << "vhost-user-fs-pci,queue-size=1024,chardev=char#{i},tag=#{name}"
    end

    if ret.any?
      ret << '-object' << "memory-backend-file,id=m0,size=#{config[:memory]}M,mem-path=/dev/shm,share=on"
      ret << '-numa' << 'node,memdev=m0'
    end

    ret
  end

  def virtiofs_socket_path(mount_name)
    "/tmp/virtiofs-#{config[:name]}-#{mount_name}.sock"
  end

  def gen_mac_address
    "00:60:2f:#{SecureRandom.hex(3).chars.each_slice(2).map(&:join).join(':')}"
  end
end

if ARGV.length != 1
  warn "Usage: #{$0} <config file>"
  exit(false)
end

r = QemuRunner.new(JSON.parse(File.read(ARGV[0]), symbolize_names: true))
r.start
