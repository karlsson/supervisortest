import driver
import gleam
import gleam/erlang/process
import gleam/erlang/reference.{type Reference}
import gleam/io
import gleam/otp/static_supervisor as sup
import worker

pub fn main() {
  process.spawn(supervisorproc)
  process.sleep_forever()
}

fn supervisorproc() {
  // observer_start()
  let worker_name = process.new_name("worker")
  let worker_subject = process.named_subject(worker_name)
  io.debug(worker_name)
  let worker_child =
    sup.worker_child("worker", fn() {
      worker.start_link(worker_name, worker_subject)
    })
  let driver_child =
    sup.worker_child("driver", fn() { driver.start_link(worker_subject) })

  let assert gleam.Ok(_) = supervise(worker_child, driver_child)
  process.sleep_forever()
}

fn supervise(worker_child: sup.ChildBuilder, driver_child: sup.ChildBuilder) {
  sup.new(sup.OneForOne)
  |> sup.add(worker_child)
  |> sup.add(driver_child)
  |> sup.start_link
}

@external(erlang, "erlang_functions", "create_ets_table")
pub fn create_ets_table(table_name: String) -> Result(Reference, String)

type ErlangResult {
  Ok
}

@external(erlang, "observer", "start")
fn observer_start() -> ErlangResult
