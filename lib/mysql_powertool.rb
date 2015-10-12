require 'active_record/base'

class MysqlPowertool< ActiveRecord::Base

  self.abstract_class = true

  # ------------------------------------------------------------
  # Class Methods
  # ------------------------------------------------------------
  class << self

    def release_connection
      connection_pool.release_connection
    end

    def database_list
      select_all("show databases").collect { |row| row.values.first }
    end

    def use(database)
      execute "use #{database}"
    end

    def tables_list(database = nil)
      use(database) if database
      select_all("show tables").collect { |row| row.values.first }
    end

    def table_columns(table, database = nil)
      use(database) if database
      select_all("describe `#{table}`")
    end

    def split_table_name(ftable_name)
      tbparts = ftable_name.split('.').collect { |tp| tp.tr('`','') }
      raise "Invalid table name: #{ftable_name}" if tbparts.size > 2
      tbparts
    end

    def select_all(sql)
      connection.select_all(sql)
    end

    # pass a block
    def stream_select(sql)
      ar_jdbc_con = connection.instance_variable_get(:@connection).instance_variable_get(:@connection)
      res = nil
      res_done = false
      stmt = ar_jdbc_con.createStatement
      begin
        stmt.enableStreamingResults
        res = stmt.executeQuery(sql)
        meta = res.meta_data
        column_data = []
        (1..meta.getColumnCount).each { |idx| column_data << [idx, meta.columnName(idx), meta.getColumnType(idx)] }
        while res.next
          row = {}
          column_data.each { |idx, name, type|
            case type
            when -6,4,5
              lv = res.getLong(idx)
              if lv == 0 && res.wasNull
                row[name] = nil
              else
                row[name] = lv
              end
            when -7, 16
              bv = res.getBoolean(idx)
              row[name] = res.wasNull ? nil : (bv ? 1 : 0)
            when 6,7,8
              dv = res.getDouble(idx)
              if dv == 0.0 && res.wasNull
                row[name] = nil
              else
                row[name] = dv
              end
            else
              val = res.getObject(idx)
              if val.is_a? Java::JavaSql::Timestamp
                row[name] = Time.at((val.getTime / 1000) - (val.getTimezoneOffset * 60)).to_s(:db)
              elsif val.is_a? Java::JavaSql::Date
                row[name] = val.to_s.to_date.to_s(:db)
              else
                row[name] = val
              end
            end
          }
          yield(row)
        end
        res_done = ! res.next
      ensure
        if res && res_done
          res.close
        elsif res

        end
        stmt.close
      end
    end

    def execute(sql)
      connection.execute(sql)
    end

    # SQL Utility for combining WHERE clauses
    #
    def clause_combo(*clauses)
      cond = ''
      clauses.each { |cl|
        if ! cl.blank?
          if cond.empty?
            cond = cl
          else
            cond << " AND (#{cl})"
          end
        end
      }
      return cond unless cond.empty?
      nil
    end

    def sanitize_sql(sql, params = {})
      params = [ params ] unless params.is_a?(Array)
      send(:sanitize_sql_array, [sql, *params])
    end

  end

  # ------------------------------------------------------------
  # Instance Methods
  # ------------------------------------------------------------


end

