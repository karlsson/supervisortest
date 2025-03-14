import gleam/erlang/process.{type Subject}
import gleam/function
import gleam/io
import gleam/otp/actor
import gleam/string
import worker

pub const my_name = "driver"

type State {
  State(
    worker_subject: Subject(worker.WorkerMessage),
    mysubject: Subject(String),
  )
}

pub fn start_link(
  worker_subject: Subject(worker.WorkerMessage),
) -> Result(process.Pid, a) {
  let assert Ok(actor.Started(pid, _subject1)) =
    actor.new_with_initialiser(100, fn() { init(worker_subject) })
    |> actor.on_message(loop)
    |> actor.start()
  Ok(pid)
}

fn init(
  worker_subject: Subject(worker.WorkerMessage),
) -> Result(actor.Initialised(State, String, Subject(String)), String) {
  let self = string.inspect(process.self())
  io.println("driver init: " <> self)
  echo worker_subject
  let mysubject = process.new_subject()
  let selector =
    process.new_selector() |> process.selecting(mysubject, function.identity)

  let state = State(worker_subject, mysubject)

  let initialised =
    actor.initialised(state)
    |> actor.selecting(selector)
    |> actor.returning(mysubject)

  process.send_after(mysubject, 100, "continue")
  Ok(initialised)
}

fn loop(state: State, _msg: String) -> actor.Next(State, String) {
  let line = get_line("enter a command: ")
  actor.call(state.worker_subject, 10_000, fn(sender) {
    #(sender, string.trim(line))
  })

  process.send(state.mysubject, "continue")
  actor.continue(state)
}

@external(erlang, "io", "get_line")
fn get_line(prompt: String) -> String
