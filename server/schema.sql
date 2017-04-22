drop table if exists runs;
create table runs (
  id integer primary key autoincrement,
  title text not null,
  date text not null
);

drop table if exists run_segments;
create table run_segments (
  id integer primary key autoincrement,
  run_id integer,
  time_point time,
  speed integer,
  FOREIGN KEY(run_id) REFERENCES run(id)
)
