use arrow::error::Result;
use arrow::ipc::writer::StreamWriter;
use arrow::json::ReaderBuilder;
use arrow::record_batch::RecordBatchReader;
use std::io::{BufRead, Cursor, Read, Write};
use std::sync::Arc;

pub fn jsons_to_record_batch_reader<R: BufRead + 'static>(
    mut reader: R,
    num_lines: usize,
) -> Result<impl RecordBatchReader> {
    let br2 = &mut reader;
    let lines = br2.lines();
    let taken = lines.take(num_lines);

    // 1. Read a few lines for schema inference
    let mut jsonl: String = String::new();
    for rline in taken {
        let line: String = rline?;
        jsonl.push_str(&line);
        jsonl.push('\n');
    }

    // 2. Infer the schema
    let (schema, _) = arrow::json::reader::infer_json_schema(jsonl.as_bytes(), None)?;
    let schema = Arc::new(schema);

    // 3. Create a chained reader
    let chained_reader = Cursor::new(jsonl.into_bytes()).chain(reader);

    // 4. Create a JSON reader
    let builder = ReaderBuilder::new(schema);
    let reader = builder.build(chained_reader)?;

    Ok(Box::new(reader))
}

pub fn write_ipc_stream<W: Write>(writer: W, reader: impl RecordBatchReader) -> Result<()> {
    let schema = reader.schema();
    let mut writer = StreamWriter::try_new(writer, &schema)?;

    for batch in reader {
        writer.write(&batch?)?;
    }

    Ok(())
}

pub fn jsons2ipc<R: BufRead + 'static, W: Write>(
    reader: R,
    writer: W,
    num_lines: usize,
) -> Result<()> {
    let reader = jsons_to_record_batch_reader(reader, num_lines)?;
    write_ipc_stream(writer, reader)
}
