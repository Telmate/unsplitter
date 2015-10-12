require 'ex_task'
require 'primary'
require 'secondary'

class DbUnsplitter

  attr_accessor :dry_run

  # primary_db/secondary_db refere to entries in database.yml
  def initialize(primary_db = :db_primary, secondary_db = :db_secondary, workers = 10, dry_run = false)
    Primary.establish_connection primary_db
    Secondary.establish_connection secondary_db
    @dry_run = dry_run
    @executor = ExTask.pool('dbunsplit', workers)
  end

  # Compare rows between the primary and secondary database
  def sync_table(table_name, primary_key = 'id', mytime_column = 'updated_at', sql_filter = nil, sort = nil)
    sql = "SELECT * FROM #{table_name}"
    sql << " WHERE #{sql_filter}" if sql_filter.present?
    sql << " ORDER BY #{sort}" if sort.present?
    counter = 0
    sync_at = Time.now - 10.seconds # give a buffer to the master-master lag
    sync_sql = nil
    sync_proc = lambda do |p_row|
      pk_val = p_row[primary_key]
      begin
        s_row = Secondary.select_all("SELECT * FROM #{table_name} WHERE #{primary_key} = #{pk_val} LIMIT 1").first
        current_count = (counter += 1)
        need_sync = false
        sync_source = :primary
        if s_row

          diff = HashDiff.diff(p_row, s_row)
          if ! diff.empty?
            if mytime_column
              mytime_diff = diff.detect { |dfe| dfe[1] == mytime_column }
              if mytime_diff
                # too new (not replicated or stale transactions)
                if ((mytime_diff[2] && mytime_diff[2] > sync_at) || (mytime_diff[3] && mytime_diff[3] > sync_at))
                  need_sync = false
                else
                  need_sync = true
                  # is the secondary newer?
                  if (mytime_diff[3] && !mytime_diff[2]) || (mytime_diff[3] && mytime_diff[2] && mytime_diff[3] > mytime_diff[2])
                    sync_source = :secondary
                  end
                end
                # update in progress but other columns changing async
              elsif (p_row[mytime_column] && p_row[mytime_column] > sync_at) || (s_row[mytime_column] && s_row[mytime_column] > sync_at)
                need_sync = false
              else
                # who has more nils? pick the other guy
                p_nils, s_nils = nil_scores(diff)
                if p_nils > s_nils
                  sync_source = :secondary
                end
                need_sync = true
              end

            else # no mytime_column

              need_sync = true
              # who has more nils? pick the other guy
              p_nils, s_nils = nil_scores(diff)
              if p_nils > s_nils
                sync_source = :secondary
              end
            end
          end

          if need_sync
            puts "Secondary different #{table_name} #{primary_key} = #{pk_val} picking #{sync_source} - #{diff.inspect}"
          end

          # show a progress dot every 100 records
          if (current_count % 100) == 1
            $stderr.write '.'
            $stderr.flush
          end

        else
          need_sync = true
          puts "Secondary missing #{table_name} #{primary_key} = #{pk_val}"
        end

        if need_sync
          case sync_source
          when :primary
            src_row = p_row
            dst_model = Secondary
          when :secondary
            src_row = s_row
            dst_model = Primary
          else
            fail "Unknown sync_source #{sync_source}"
          end

          # memoize sync_sql, won't change this table
          sync_sql ||= "REPLACE INTO #{table_name} (#{src_row.keys.join(',')}) VALUES (#{src_row.keys.map { |k| ':' + k }.join(',')})"
          exec_sync_sql = dst_model.sanitize_sql(sync_sql, src_row.with_indifferent_access)

          if @dry_run
            puts exec_sync_sql
          else
            dst_model.execute exec_sync_sql
          end
        end

      rescue Exception => err
        $stderr.puts err
      end
    end # sync_proc

    # stream all the rows and add them to the work queue asap
    Primary.stream_select(sql) do |p_row|
      queue_row_work(p_row, &sync_proc)
    end
  end

  # count the diffs between the primary & secondary
  def nil_scores(diff)
    p_nils = s_nils = 0
    diff.each do |dfe|
      p_nils += 1 if dfe[2].nil?
      s_nils += 1 if dfe[3].nil?
    end
    return [p_nils, s_nils]
  end

  def queue_row_work(row, &block)
    ExTask.queue_ex_task(@executor, ExTask.new(row, &block))
  end
end
